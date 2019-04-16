module NewExcel
  module Hooks
    MIN_PROGRESS_BAR_THRESHOLD = 0

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
  end
end
