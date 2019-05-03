module NewExcel
  module BuiltInFunctions
    module Math
      # def add(*list)
      #   zipped_lists(list) do |list|
      #     inject(list, :+)
      #   end
      # end
      #
      # alias_method :sum, :add

      # def subtract(*list)
      #   zipped_lists(list) do |list|
      #     inject(list, :-)
      #   end
      # end

      # def multiply(*list)
      #   zipped_lists(list) do |list|
      #     inject(list, :*)
      #   end
      # end

      # def divide(*list)
      #   zipped_lists(list) do |num, denom|
      #     primitive_infix(:/, num, primitive_method_call(denom, :to_f))
      #   end
      # end

      # def square(*list)
      #   each_item(list) do |item|
      #     multiply(item, item)
      #   end
      # end
      #
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

      def to_number(str)
        if str.is_a?(Array)
          return str.map { |v| to_number(v) }
        end

        if str.is_a?(Numeric)
          str
        elsif str.is_a?(::String) && str.include?(".")
          primitive_method_call(str, :to_f)
        else
          primitive_method_call(str, :to_i)
        end
      end

      alias_method :value, :to_number

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

      # def average(*args)
      #   divide(
      #     apply("sum", args),
      #     length(*args))
      # end
    end
  end
end
