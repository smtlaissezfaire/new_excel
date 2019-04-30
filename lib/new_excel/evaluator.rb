module NewExcel
  class Evaluator
    def evaluate(expr, env = @env || {})
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
          #TODO: pretty sure @env should be dupped here?
          Runtime::Closure.new(expr[1], expr[2], @env)
        when :define
          env[expr[1]] = evaluate(expr[2])
        when :if
          eval_if(cdr(expr))
        when :quote
          quote(expr[1])
        when :lookup_cell
          lookup_cell(expr[1], expr[2])
        else
          fn = evaluate(function_name)
          raise "Can't find function with name: #{function_name.inspect}" unless fn
          evaluated_arguments = evaluate_list(cdr(expr))
          apply_with_explicit_environment(fn, evaluated_arguments)
        end
      when Symbol
        lookup(expr)
      when Integer, Float, TrueClass, FalseClass, String, NewExcel::Runtime::Closure, Hash
        expr
      when AST::AstBase
        evaluate(quote(expr))
      else
        raise "Unknown expression type!, expr: #{expr.inspect}"
      end
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

    def lookup(expr)
      val ||= @env[expr]
      val ||= lookup_cell(expr, NewExcel::ProcessState.current_sheet_name) if expr.is_a?(Symbol)
      val
    end

    def lookup_cell(cell_name, sheet_name)
      file = NewExcel::ProcessState.current_file

      return if !file

      if sheet_name && ProcessState.current_sheet_name == sheet_name
        sheet = ProcessState.current_sheet
        sheet.parse

        if sheet.column_names.include?(cell_name.to_s)
          column_function = sheet.evaluated_with_unevaluated_columns[cell_name]

          # if it's arity = 0 (aka no arguments, we evaluate it - otherwise, we return the function)
          # to be called later
          if column_function[1].length == 0
            evaluate([column_function])
          else
            column_function
          end
        end
      else
        sheet = file.get_sheet(sheet_name.to_s)

        sheet.parse
        sheet.get_column(cell_name.to_s)
      end
    end

    def apply_with_explicit_environment(fn, arguments)
      with_env(@env) do
        if primitive_function?(fn)
          apply_primitive(fn, arguments)
        elsif fn.is_a?(Runtime::Closure)
          evaluate(fn.body, bind(fn.formal_arguments, arguments))
        elsif fn.is_a?(Array) && fn[0] == :lambda
          bound_function = evaluate(fn)
          apply_with_explicit_environment(bound_function, arguments)
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

    def bind(formal_arguments, evaluated_arguments)
      new_env = {}

      formal_arguments.zip(evaluated_arguments) do |l1, l2|
        new_env[l1] = l2
      end

      merge_envs(@env, new_env)
    end

    def merge_envs(old_env, new_env)
      old_env = extract_primitive_hash(old_env)
      new_env = extract_primitive_hash(new_env)
      old_env.merge(new_env)
    end

    def extract_primitive_hash(obj)
      if obj.is_a?(Array) && obj[0] == :hash_map
        obj[1]
      elsif obj.is_a?(Hash)
        obj
      else
        raise "Data error! Not sure how extract hash from obj: #{obj.inspect}"
      end
    end

    def primitive_function?(fn)
      fn.is_a?(Proc) || fn.is_a?(Method) || fn.is_a?(UnboundMethod)
    end

    def apply_primitive(fn, arguments)
      if fn.is_a?(UnboundMethod)
        fn = fn.bind(self)
      end
      fn.call(*arguments)
    end

    def car(list)
      list[0]
    end

    def cdr(list)
      list.slice(1, list.length)
    end

    def quote(obj)
      case obj
      when Symbol, Array, Integer, Float, TrueClass, FalseClass, String, Hash
        obj
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
        hash = {}
        obj.to_hash.each do |key, value|
          hash[quote(key)] = quote(value)
        end
        hash
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
  end
end
