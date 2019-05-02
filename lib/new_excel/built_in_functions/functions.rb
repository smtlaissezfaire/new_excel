module NewExcel
  module BuiltInFunctions
    module Functions
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
    end
  end
end
