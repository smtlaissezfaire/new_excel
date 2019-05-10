module NewExcel
  module BuiltInFunctions
    module List
      def inject(list, symbol_or_proc)
        # primitive_method_call(list, :inject, &symbol_or_proc)
        list.inject(&symbol_or_proc)
      end

      def count(*args)
        primitive_method_call(primitive_method_call(args, :flatten), :length)
      end

      def length(args)
        primitive_method_call(args, :length)
      end

      # def concat(*args)
      #   zipped_lists(args, &:join)
      # end

      def list(*args)
        args
      end

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

      def each(list)
        vals = []

        list.each_with_index do |_, index|
          vals << index(list, 1, index + 1)
        end

        vals
      end

      def flatten(list)
        primitive_method_call(list, :flatten)
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

      def index(list, val1=nil, val2=nil)
        if val1 && !val2
          list[val1-1]
        elsif val1 || val2
          val1 ||= 1
          list[val1-1..val2-1]
        else
          1.upto(list.length).to_a
        end
      end

      def is_list(list)
        list.is_a?(Array)
      end
    end
  end
end
