module NewExcel
  module BuiltInFunctions
    module DateTime
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

      def hour(*list)
        each_item(list) do |time|
          primitive_method_call(time, :hour)
        end
      end
    end
  end
end
