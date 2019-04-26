module NewExcel
  module BuiltInFunctions
    include ListHelpers
    extend self

    def evaluate(str)
      Evaluator.evaluate(self, "= #{str}")
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

    def add(*list)
      zipped_lists(list) do |list|
        list.inject(&:+)
      end
    end

    alias_method :sum, :add

    def subtract(*list)
      zipped_lists(list) do |list|
        list.inject(&:-)
      end
    end

    def multiply(*list)
      zipped_lists(list) do |list|
        list.inject(&:*)
      end
    end

    def divide(*list)
      zipped_lists(list) do |num, denom|
        num / denom.to_f
      end
    end

    def count(*args)
      args.flatten.length
    end

    alias_method :length, :count

    def to_number(str)
      if str.is_a?(Array)
        return str.map { |v| to_number(v) }
      end

      if str.is_a?(Numeric)
        str
      elsif str.is_a?(String) && str.include?(".")
        str.to_f
      else
        str.to_i
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
        array.reverse
      end
    end

    def first(list)
      each_list(list) do |array|
        array.first
      end
    end

    def lookback(list, length)
      reverse(take(reverse(list), length))
    end

    def compact(list)
      each_list(list) do |list|
        list.compact
      end
    end

    def last(list)
      each_list(list) do |list|
        list.last
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

    def apply(fn, arguments)
      method(fn).call(*arguments)
    end

    def call(fn, arguments)
      method(fn).call(arguments)
    end

    def abs(*list)
      each_item(list) do |item|
        item.abs
      end
    end

    def max(*list)
      zipped_lists(list) do |list|
        list.max
      end
    end

    def min(*list)
      zipped_lists(list) do |list|
        list.min
      end
    end

    def flatten(list)
      list.flatten
    end

    def eq(*list)
      zipped_lists(list) do |vals|
        vals.inject(&:==)
      end
    end

    def gt(*list)
      zipped_lists(list) do |val1, val2|
        begin
          val1 > val2
        rescue => e
        end
      end
    end

    def gte(*list)
      zipped_lists(list) do |val1, val2|
        val1 >= val2
      end
    end

    def lte(*list)
      zipped_lists(list) do |val1, val2|
        val1 <= val2
      end
    end

    def lt(*list)
      zipped_lists(list) do |val1, val2|
        val1 < val2
      end
    end

    def hour(*list)
      each_item(list) do |time|
        time.hour
      end
    end

    def any?(*list)
      zipped_lists(list) do |list|
        list.any?
      end
    end

    def square(*list)
      each_item(list) do |item|
        item ** 2
      end
    end

    def append(list, *values)
      values.each do |value|
        list.append(value)
      end

      list
    end
  end
end
