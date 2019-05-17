module NewExcel
  module BuiltInFunctions
    module Functions
      def map(fn, items)
        return [] if items.empty?

        values = []

        items.each_with_index do |item|
          if item.is_a?(Array)
            values << apply(fn, item)
          else
            values << apply(fn, [item])
          end
        end

        values
      end

      def fold(fn, list, initial=nil)
        apply(fn, list)
      end

      def call(fn, arguments)
        method(fn).call(arguments)
      end
    end
  end
end
