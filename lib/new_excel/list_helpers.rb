module NewExcel
  module ListHelpers

  private

    def each_list(args, &block)
      if args.any? { |n| n.is_a?(Array) }
        args.map do |inner_args|
          yield inner_args
        end
      else
        yield args
      end
    end

    def zipped_lists(list, &block)
      list = to_list(*list)

      if list.any? { |list| list.is_a?(Array) }
        list.map do |l|
          yield l
        end
      else
        yield list
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
      elsif list.is_a?(Array)
        list
      else
        [list]
      end
    end
  end
end
