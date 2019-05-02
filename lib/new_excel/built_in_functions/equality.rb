module NewExcel
  module BuiltInFunctions
    module Equality
      def eq(*list)
        zipped_lists(list) do |vals|
          inject(vals, :==)
        end
      end
    end
  end
end
