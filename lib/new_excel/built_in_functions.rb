module NewExcel
  module BuiltInFunctions
    include ListHelpers
    extend self

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
          env[expr[1].to_sym] = evaluate(expr[2])
        when :if
          eval_if(cdr(expr))
        when :quote
          quote(expr[1])
        when :lookup_cell
          lookup_cell(expr[1], expr[2])
        when :progn
          progn(cdr(expr))
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
      when Integer, Float, TrueClass, FalseClass, String, NewExcel::Runtime::Closure
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

    def get(expr)
      @env[expr]
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

    def lookup_cell(cell_name, sheet_name)
      file = NewExcel::ProcessState.current_file

      return if !file

      if sheet_name && ProcessState.current_sheet_name == sheet_name
        raise "Shouldn't have gotten here. Call lookup(expr)"
      end

      sheet = file.get_sheet(sheet_name.to_s)

      sheet.parse
      sheet.get_column(cell_name.to_s)
    end

    def apply(fn, arguments)
      fn = fn.to_sym if fn.is_a?(String)

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

      formal_arguments.zip(evaluated_arguments) do |l1, l2|
        new_env[l1] = l2
      end

      merge_envs(@env, function_binding, new_env)
    end

    def merge_envs(*envs)
      envs.inject(&:merge)
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
      when Symbol, Array, Integer, Float, TrueClass, FalseClass, String
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

    # macros

    def if(*args)
      conds, truthy_expressions, falsy_expressions = args

      zipped_lists([_evaluate(conds), truthy_expressions, falsy_expressions], evaluate: false) do |cond, truthy_expression, falsy_expression|
        cond ? _evaluate(truthy_expression) : _evaluate(falsy_expression)
      end
    end

    def and(*list)
      zipped_lists(list) do |list|
        list.inject { |v1, v2| v1 && v2 }
      end
    end

    def or(*list)
      zipped_lists(list) do |list|
        val = nil
        list.map do |obj|
          val = _evaluate(obj)
          break if val
        end
        val
      end
    end

    # "regular" functions

    def inject(list, symbol_or_proc)
      # primitive_method_call(list, :inject, &symbol_or_proc)
      list.inject(&symbol_or_proc)
    end

    def add(*list)
      zipped_lists(list) do |list|
        inject(list, :+)
      end
    end

    alias_method :sum, :add

    def subtract(*list)
      zipped_lists(list) do |list|
        inject(list, :-)
      end
    end

    def multiply(*list)
      zipped_lists(list) do |list|
        inject(list, :*)
      end
    end

    def divide(*list)
      zipped_lists(list) do |num, denom|
        primitive_infix(:/, num, primitive_method_call(denom, :to_f))
      end
    end

    def square(*list)
      each_item(list) do |item|
        multiply(item, item)
      end
    end

    def count(*args)
      primitive_method_call(primitive_method_call(args, :flatten), :length)
    end

    alias_method :length, :count

    def to_number(str)
      if str.is_a?(Array)
        return str.map { |v| to_number(v) }
      end

      if str.is_a?(Numeric)
        str
      elsif str.is_a?(String) && str.include?(".")
        primitive_method_call(str, :to_f)
      else
        primitive_method_call(str, :to_i)
      end
    end

    alias_method :value, :to_number

    def concat(*args)
      zipped_lists(args, &:join)
    end

    def left(*args)
      zipped_lists(args) do |str, num|
        str[0..num-1]
      end
    end

    def mid(*args)
      zipped_lists(args) do |str, starting_at, extract_length|
        i1 = starting_at-1
        i2 = i1 + extract_length

        str[i1..i2]
      end
    end

    def right(*args)
      zipped_lists(args) do |str, num|
        str[-num..-1]
      end
    end

    def search(*args)
      zipped_lists(args) do |search_for, text_to_search, starting_at|
        starting_at = 1 if !starting_at

        i1 = starting_at-1
        i2 = text_to_search.length-1

        text_to_search = text_to_search[i1..i2]

        starting_at + text_to_search.index(search_for)
      end
    end

    def join(*args)
      zipped_lists(args) do |*objs|
        objs.flatten.compact.map(&:to_s).join(" ")
      end
    end

    def list(*args)
      args
    end

    def column(name)
      reference = AST::CellReference.new("dynamic cell reference")
      reference.cell_name = name
      reference.value
    end

    alias_method :c, :column

    def range(*args)
      zipped_lists(args) do |range_start, range_end|
        (range_start..range_end).to_a
      end
    end

    def take(list, count)
      each_list(list) do |list|
        list[0..count]
      end
    end

    def reverse(list)
      each_list(list) do |array|
        primitive_method_call(array, :reverse)
      end
    end

    def first(list)
      each_list(list) do |array|
        primitive_method_call(array, :first)
      end
    end

    def lookback(list, length)
      reverse(take(reverse(list), length))
    end

    def compact(list)
      each_list(list) do |list|
        primitive_method_call(list, :compact)
      end
    end

    def last(list)
      each_list(list) do |list|
        primitive_method_call(list, :last)
      end
    end

    def index(list, val1=nil, val2=nil)
      if val1 || val2
        val1 ||= 1
        list[val1-1..val2-1]
      else
        1.upto(list.length).to_a
      end
    end

    def average(*args)
      divide(sum(*args), length(*args))
    end

    def each(list)
      vals = []

      list.each_with_index do |_, index|
        vals << index(list, 1, index + 1)
      end

      vals
    end

    def date(strs)
      each_list(strs) do |list|
        list.map do |str|
          Date.parse(str)
        end
      end
    end

    def time(*strs)
      each_item(strs) do |str|
        Time.parse(str)
      end
    end

    def map(fn, lists)
      return [] if lists.empty?
      values = []

      lists.each_with_index do |list|
        values << apply(fn, list)
      end

      values
    end

    def fold(fn, list, initial=nil)
      apply(fn, list)
    end

    def call(fn, arguments)
      method(fn).call(arguments)
    end

    def abs(*list)
      each_item(list) do |item|
        primitive_method_call(item, :abs)
      end
    end

    def max(*list)
      zipped_lists(list) do |list|
        primitive_method_call(list, :max)
      end
    end

    def min(*list)
      zipped_lists(list) do |list|
        primitive_method_call(list, :min)
      end
    end

    def flatten(list)
      primitive_method_call(list, :flatten)
    end

    def eq(*list)
      zipped_lists(list) do |vals|
        inject(vals, :==)
      end
    end

    def gt(*list)
      zipped_lists(list) do |val1, val2|
        begin
          primitive_infix(:>, val1, val2)
        rescue => e
        end
      end
    end

    def gte(*list)
      zipped_lists(list) do |val1, val2|
        primitive_infix(:>=, val1, val2)
      end
    end

    def lte(*list)
      zipped_lists(list) do |val1, val2|
        primitive_infix(:<=, val1, val2)
      end
    end

    def lt(*list)
      zipped_lists(list) do |val1, val2|
        primitive_infix(:<, val1, val2)
      end
    end

    def hour(*list)
      each_item(list) do |time|
        primitive_method_call(time, :hour)
      end
    end

    def any?(*list)
      zipped_lists(list) do |list|
        primitive_method_call(list, :any?)
      end
    end

    def append(list, *values)
      each_list(values) do |value|
        primitive_method_call(list, :append, [value])
      end

      list
    end

    # primitives

    def primitive_method_call(obj, method, arguments=[])
      obj.public_send(method, *arguments)
    end

    def primitive_infix(method, val1, val2)
      primitive_method_call(val1, method, [val2])
    end
  end
end
