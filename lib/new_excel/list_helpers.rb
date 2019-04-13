module NewExcel
  module ListHelpers

  private

    def inject(*list, &fn)
      ambiguous_map(*list) do |list|
        list.inject(&fn)
      end
    end

    def ambiguous_map(*args)
      res = to_list(*args)

      if res.is_a?(Array) && res[0].is_a?(Array)
        res.map { |x| yield x }
      else
        yield res
      end
    end

    def to_list(*list)
      if list.any? { |list| list.is_a?(Array) }
        longest_list_length = list.map { |l| l.is_a?(Array) ? l.length : 0 }.max

        list = list.map do |sublist|
          if sublist.is_a?(Array)
            sublist
          else
            [sublist] * longest_list_length
          end
        end

        l1 = list.shift
        l1.zip(*list)
      else
        Array(list)
      end
    end
  end
end
