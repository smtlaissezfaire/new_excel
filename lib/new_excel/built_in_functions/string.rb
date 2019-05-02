module NewExcel
  module BuiltInFunctions
    module String
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
    end
  end
end
