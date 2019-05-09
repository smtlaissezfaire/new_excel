module NewExcel
  module BuiltInFunctions
    module Evaluator
      def evaluate(expr, env = @env || Runtime.base_environment)
        @env = env

        if ProcessState.debug
          begin
            puts "evaluate: #{quote(expr)}"
          rescue => e
            puts "ERROR quoting: #{expr.inspect}"
          end
        end

        case expr
        when Array
          function_name = car(expr)

          case function_name
          when :lambda
            Runtime::Closure.new(expr[1], expr[2], @env)
          when :define
            @env.define(expr[1].to_sym, evaluate(expr[2]))
          when :set!
            @env.set!(expr[1].to_sym, evaluate(expr[2]))
          when :if
            self.send(:if, cdr(expr))
          when :quote
            quote(expr[1])
          when :lookup_cell
            lookup_cell(expr[1], expr[2])
          when :progn
            progn(cdr(expr))
          when :and
            self.send(:and, cdr(expr))
          else
            fn = evaluate(function_name)
            raise "Can't find function with name: #{function_name.inspect}" unless fn
            evaluated_arguments = evaluate_list(cdr(expr))
            apply(fn, evaluated_arguments)
          end
        when Symbol
          lookup(expr)
        when Hash
          statements = expr.map do |key, value|
            [:define, key, value]
          end

          call(:progn, statements)
        when Integer, Float, TrueClass, FalseClass, ::String, NewExcel::Runtime::Closure
          expr
        when AST::AstBase
          evaluate(quote(expr))
        else
          raise "Unknown expression type!, expr: #{expr.inspect}"
        end
      end

      def parse(str)
        quote(NewExcel::Parser.new.parse(str))
      end

      def progn(expressions=[])
        last_value = nil
        expressions.each do |expression|
          last_value = evaluate(expression)
        end
        last_value
      end

      def evaluate_list(list)
        list.map do |item|
          evaluate(item)
        end
      end

      def eval_if(clauses)
        cond, true_expr, false_expr = clauses

        if evaluate(cond)
          evaluate(true_expr)
        else
          evaluate(false_expr)
        end
      end

      def if(args)
        conds, truthy_expressions, falsy_expressions = args

        conds = evaluate(conds)

        if conds.is_a?(Array)
          truthy_expressions = evaluate(truthy_expressions)
          falsy_expressions = evaluate(falsy_expressions)

          truthy_is_array = truthy_expressions.is_a?(Array)
          falsy_is_array = falsy_expressions.is_a?(Array)

          index = 0
          conds.map do |cond|
            value = if cond
              truthy_is_array ? truthy_expressions[index] : truthy_expressions
            else
              falsy_is_array ? falsy_expressions[index] : falsy_expressions
            end

            index += 1
            value
          end
        else
          if conds
            evaluate(truthy_expressions)
          else
            evaluate(falsy_expressions)
          end
        end
      end

      def get(expr)
        @env.get(expr)
      end

      def lookup(expr)
        val = get(expr)

        if val.is_a?(NewExcel::AST::Function)
          if val.formal_arguments == []
            evaluate([val])
          else
            evaluate(val)
          end
        else
          val
        end
      end

      def get_as_string_name(reference)
        case reference
        when ::String
          reference
        when Symbol
          reference.to_s
        when Array
          ref = evaluate(reference)
          # it's a function / column
          ref = ref.first
          # sometimes this comes back as AST::String?
          evaluate(ref)
        else
          raise "Invalid sheet_name: #{sheet_name.inspect}, class: #{sheet_name.class}"
        end
      end

      def lookup_cell(cell_name, sheet_name)
        file = NewExcel::ProcessState.current_file
        return if !file

        sheet_name = get_as_string_name(sheet_name)
        cell_name = get_as_string_name(cell_name)

        sheet = file.get_sheet(sheet_name)
        sheet.parse
        sheet.get_column(cell_name)
      end

      def apply(fn, arguments)
        fn = fn.to_sym if fn.is_a?(::String)

        with_env(@env) do
          if primitive_function?(fn)
            apply_primitive(fn, arguments)
          elsif fn.is_a?(Runtime::Closure)
            evaluate(fn.body, bind(fn.formal_arguments, arguments, fn.env))
          elsif (fn.is_a?(Array) && fn[0] == :lambda) || fn.is_a?(Symbol)
            bound_function = evaluate(fn)
            apply(bound_function, arguments)
          else
            raise "Not sure how to apply function: #{fn.inspect}"
          end
        end
      end

      def with_env(env)
        old_env = @env
        @env = env
        yield
      ensure
        @env = old_env
      end

      def bind(formal_arguments, evaluated_arguments, function_binding)
        new_env = {}

        if formal_arguments.is_a?(Array)
          formal_arguments.zip(evaluated_arguments) do |l1, l2|
            new_env[l1] = l2
          end
        else
          new_env[formal_arguments] = evaluated_arguments
        end

        function_binding.merge(new_env)
      end

      def primitive_function?(fn)
        fn.is_a?(Proc) || fn.is_a?(Method) || fn.is_a?(UnboundMethod)
      end

      def apply_primitive(fn, arguments)
        if fn.is_a?(UnboundMethod)
          fn = fn.bind(self)
        end

        if arguments.last.is_a?(NewExcel::Runtime::Closure)
          old_closure = arguments.pop
          block = lambda { |*args| apply(old_closure, *args) }
        end

        fn.call(*arguments, &block)
      end

      def car(list)
        list[0]
      end

      def cdr(list)
        list.slice(1, list.length)
      end

      def quote(obj)
        case obj
        when Symbol, Array, Integer, Float, TrueClass, FalseClass, ::String
          obj
        when Hash
          statements = obj.map do |key, value|
            [:define, quote(key), quote(value)]
          end
          [:progn, *statements]
        when AST::Symbol
          obj.symbol
        when AST::Primitive
          obj.value
        when AST::Function
          [:lambda, quote_list(obj.formal_arguments)] + quote_list(obj.body)
        when AST::FunctionCall
          [quote(obj.reference)] + quote_list(obj.arguments)
        when AST::FunctionReference
          if obj.anonymous?
            quote(obj.function)
          else
            quote(obj.name)
          end
        when AST::KeyValuePair
          [:define, quote(obj.key), quote(obj.value)]
        when AST::FileReference
          [:lookup_cell, quote(obj.symbol),
                         quote(obj.file_reference)]
        when AST::Map
          quote(obj.to_hash)
        when AST::StatementList
          [:progn, *quote_list(obj.statements)]
        when Method, UnboundMethod
          obj
        else
          raise "Not sure how to quote: #{obj.inspect}"
        end
      end

      def quote_list(lst)
        lst.map { |l| quote(l) }
      end

      def hash_map(args)
        Hash[*args]
      end

      # TODO: This current evaluates all columns. That sucks.
      # Would also be nice to unify the behavior of NewExcel::AST::Function
      # in lookup() so that all function types act the same way.  A call to:
      # = foo should evaluate the function foo().  If you wanted the raw function,
      # you could use function(foo).  And overall, functions / columns should
      # all be lazy, not eager.  This also includes included columns
      def include(sheet_name)
        file = NewExcel::ProcessState.current_file

        return if !file

        if sheet_name && ProcessState.current_sheet_name == sheet_name
          raise "Can't include() from the current file!"
        end

        sheet = file.get_sheet(sheet_name.to_s)

        sheet.parse
        evaluate(sheet.ast)
      end
    end
  end
end
