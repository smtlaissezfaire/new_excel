module NewExcel
  module Hooks
    MIN_PROGRESS_BAR_THRESHOLD = 1000

    # progress_bar = nil
    #
    # Event.listen(Event::MAP_STARTED_PROCESSING) do |length:|
    #   # next if length < MIN_PROGRESS_BAR_THRESHOLD
    #
    #   sheet_name = ProcessState.current_sheet_name || "sheet"
    #   if !progress_bar
    #     progress_bar = ProgressBar.create
    #   else
    #     progress_bar.reset
    #   end
    #   progress_bar.format = "Loading #{sheet_name} |%b>%i| %p%% %c of %C %t"
    #   progress_bar.total = length
    # end
    #
    # Event.listen(Event::MAP_COLUMN_STARTED_PROCESSING) do |column_name:|
    #   progress_bar.title = "Column: #{column_name}"
    #   progress_bar.increment
    # end
    #
    # Event.listen(Event::GET_BODY_VALUES) do |length:|
    #   next if length < MIN_PROGRESS_BAR_THRESHOLD
    #
    #   sheet_name = ProcessState.current_sheet_name || "sheet"
    #   progress_bar = ProgressBar.create(format: "Loading #{sheet_name} |%b>%i| %p%% %c of %C %t", total: length)
    #
    #   call_count = 1
    #
    #   Event.listen(Event::INCREMENT_BODY_VALUE) do
    #     progress_bar.increment
    #
    #     call_count += 1
    #     if call_count > length
    #       Event.unsubscribe(Event::INCREMENT_BODY_VALUE)
    #     end
    #   end
    # end

    class << self

      def debug(msg)
        return unless debug?
        puts "DEBUG #{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}: #{msg}"
      end

      def debug_indented(msg)
        debug("  #{msg}")
      end

      def debug?
        ProcessState.debug
      end

      def install!
        Event.listen(Event::DEBUG_MAP) do |map, keys, values|
          next unless ProcessState.debug

          debug "map:"

          keys.each_with_index do |key, index|
            debug_indented "#{key}: #{values[index]}"
          end
        end

        Event.listen(Event::DEBUG_FUNCTION) do |name, arguments, environment|
          next unless ProcessState.debug
          debug "function: #{name.to_s.blue}"
          debug_indented "arguments: #{arguments}"
          debug_indented "environment: #{environment}"
        end

        Event.listen(Event::DEBUG_FUNCTION_RESULT) do |result|
          next unless ProcessState.debug
          debug_indented "result: #{result.to_s.red}"
        end
      end
    end
  end
end

NewExcel::Hooks.install!
