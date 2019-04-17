module NewExcel
  module Hooks
    MIN_PROGRESS_BAR_THRESHOLD = 1000

    Event.listen(Event::GET_BODY_VALUES) do |length:|
      next if length < MIN_PROGRESS_BAR_THRESHOLD

      sheet_name = ProcessState.current_sheet_name || "sheet"
      progress_bar = ProgressBar.create(format: "Loading #{sheet_name} |%b>%i| %p%% %c of %C %t", total: length)

      call_count = 1

      Event.listen(Event::INCREMENT_BODY_VALUE) do
        progress_bar.increment

        call_count += 1
        if call_count > length
          Event.unsubscribe(Event::INCREMENT_BODY_VALUE)
        end
      end
    end

    Event.listen(Event::DEBUG_MAP) do |map, values_by_column, kv_pairs|
      map.instance_eval do
        debug "map:"

        values_by_column.each_with_index do |col_values, index|
          debug_indented "#{kv_pairs[index].hash_key}: #{col_values}"
        end
      end
    end

    Event.listen(Event::DEBUG_FUNCTION) do |function_call, evaluated_arguments|
      function_call.instance_eval do
        debug "function: #{print}"
        debug_indented "name: #{name}"
        debug_indented "arguments: #{evaluated_arguments}"
      end
    end

    Event.listen(Event::DEBUG_FUNCTION_RESULT) do |function_call, result|
      function_call.instance_eval do
        debug_indented "result: #{result}"
      end
    end
  end
end
