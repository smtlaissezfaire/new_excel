module NewExcel
  module BuiltInFunctions
    module DateTime
      def date(strs)
        if strs.is_a?(Array)
          each_list(strs) do |list|
            list.map do |str|
              date(str)
            end
          end
        else
          Date.parse(strs)
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
