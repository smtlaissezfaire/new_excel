module NewExcel
  module BuiltInFunctions
    include ListHelpers
    extend self

    def evaluate(str)
      Evaluator.evaluate(self, "= #{str}")
    end

    def add(*list)
      inject(*list, &:+)
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

    def to_number(str)
      if str.is_a?(Array)
        return str.map { |v| value(v) }
      end

      if str.is_a?(Numeric)
        str
      elsif str.include?(".")
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
      [args]
    end

    def explode(*args)
      args
    end

    def column(name)
      reference = AST::CellReference.new("dynamic cell reference")
      reference.cell_name = name
      reference.value
    end

    alias_method :c, :column
  end
end
