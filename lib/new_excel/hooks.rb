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

    Event.listen(Event::DEBUG_MAP) do |map, keys, values|
      next unless ProcessState.debug

      map.instance_eval do
        debug "map:"

        keys.each_with_index do |key, index|
          debug_indented "#{key}: #{values[index]}"
        end
      end
    end

    Event.listen(Event::DEBUG_FUNCTION) do |function_call, evaluated_arguments|
      next unless ProcessState.debug

      function_call.instance_eval do
        debug "function: #{print}"
        debug_indented "name: #{name}"
      end
    end

    Event.listen(Event::DEBUG_FUNCTION_ARGUMENT) do |arguments|
      next unless ProcessState.debug

      # TODO: this shouldn't reload/re-evaluate stuff!
      values = arguments.map(&:value)
      debug_indented "arguments: #{arguments.map(&:values)}"
    end


    Event.listen(Event::DEBUG_FUNCTION_RESULT) do |function_call, result|
      next unless ProcessState.debug

      function_call.instance_eval do
        debug_indented "result: #{result}"
      end
    end
  end
end
