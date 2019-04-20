module NewExcel
  module BuiltInFunctions
    include ListHelpers
    extend self

    def evaluate(str)
      Evaluator.evaluate(self, "= #{str}")
    end

    # TODO: need to figure out the right way to do these things...
    def add(*list)
      list.flatten.inject(&:+)
    end

    alias_method :sum, :add

    def subtract(*list)
      inject(*list, &:-)
    end

    def multiply(*list)
      inject(*list, &:*)
    end

    def divide(num, denom)
      inject(num, denom.to_f, &:/)
    rescue ZeroDivisionError
      "DIV!"
    end

    def count(*args)
      args.flatten.length
    end

    alias_method :length, :count

    def make_list(list)
      list = list[0] if list.any? { |l| l.is_a?(Array) }
      list
    end

    def to_number(str)
      if str.is_a?(Array)
        return str.map { |v| value(v) }
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
      ambiguous_map(*args, &:join)
    end

    def left(*args)
      ambiguous_map(*args) do |str, num|
        str[0..num-1]
      end
    end

    def mid(*args)
      ambiguous_map(*args) do |str, starting_at, extract_length|
        i1 = starting_at-1
        i2 = i1 + extract_length

        str[i1..i2]
      end
    end

    def right(*args)
      ambiguous_map(*args) do |str, num|
        str[-num..-1]
      end
    end

    def search(*args)
      ambiguous_map(*args) do |search_for, text_to_search, starting_at|
        starting_at = 1 if !starting_at

        i1 = starting_at-1
        i2 = text_to_search.length-1

        text_to_search = text_to_search[i1..i2]

        starting_at + text_to_search.index(search_for)
      end
    end

    def join(*args)
      ambiguous_map(*args) do |*objs|
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
      ambiguous_map(*args) do |range_start, range_end|
        (range_start..range_end).to_a
      end
    end

    def pick2(list, start=1)
      index = start
      list.map do |l|
        l.slice(0, index).tap do
          index += 1
        end
      end
    end

    def take(list, count)
      list_map(list) do |list|
        list[0..count]
      end
    end

    def reverse(list)
      list_map(list) do |array|
        array.reverse
      end
    end

    def first(list)
      list_map(list) do |array|
        array.first
      end
    end

    def lookback(list, length)
      reverse(take(reverse(list), length))
    end

    def compact(list)
      list_map(list) do |list|
        list.compact
      end
    end

    def last(list)
      list_map(list) do |list|
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

    def slice(list, nums)
      nums = [nums] * list.length if nums.is_a?(Integer)

      i = 0

      list.map do |l|
        if nums[i]
          list.slice(0, nums[i]).tap do
            i += 1
          end
        end
      end
    end

    # def average(*args)
    #   if args[0].is_a?(Array)
    #     list = args[0]
    #   else
    #     list = args
    #   end
    #
    #   if list.any? { |x| x.is_a?(Array) }
    #     list.map do |list|
    #       average(list)
    #     end
    #   else
    #     list = list.compact
    #
    #     begin
    #       divide(sum(list), count(list))
    #     rescue => e
    #       nil
    #     end
    #   end
    # end

    def average(*args)
      divide(sum(*args), length(*args))
    end

    def upto(list, offset=0)
      slice(list, index(list).map { |x| x + offset})
    end

    # alias_method :each, :upto

    def each(list)
      vals = []

      list.each_with_index do |_, index|
        vals << index(list, 1, index + 1)
      end

      vals
    end

    def current(list)
      upto(list)
    end

    def list_map(args, &block)
      if args.any? { |n| n.is_a?(Array) }
        args.map do |inner_args|
          yield inner_args
        end
      else
        yield args
      end
    end

    def date(strs)
      list_map(strs) do |list|
        list.map do |str|
          Date.parse(str)
        end
      end
    end

    def time(strs)
      list_map(strs) do |list|
        list.map do |str|
          Time.parse(str)
        end
      end
    end

    def map(fn, *lists)
      return [] if lists.empty?
      values = []

      lists[0].each_with_index do |_, index|
        indexed_items = lists.map { |l| l[index] }
        values << call(fn, indexed_items)
      end

      values
    end

    def apply(fn, arguments)
      method(fn).call(*arguments)
    end

    def call(fn, arguments)
      method(fn).call(arguments)
    end
  end
end
