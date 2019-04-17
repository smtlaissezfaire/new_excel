module NewExcel
  class Event
    module Events
      GET_BODY_VALUES = :get_body_values
      INCREMENT_BODY_VALUE = :increment_body_values
      ROW_LOADED = :row_loaded
      DEBUG_MAP = :debug_map
      DEBUG_FUNCTION = :debug_function
      DEBUG_FUNCTION_RESULT = :debug_function_result
    end

    include Events

    class << self
      def instance
        @instance ||= new
      end

      def listen(*a, &b)
        instance.listen(*a, &b)
      end

      def fire(*a, &b)
        instance.fire(*a, &b)
      end

      def unsubscribe(*a, &b)
        instance.unsubscribe(*a, &b)
      end
    end

    def listen(event_name, &block)
      events[event_name] ||= []
      events[event_name] << block
    end

    def unsubscribe(event_name)
      events.delete(event_name)
    end

    def fire(event_name, *args)
      if events[event_name] && events[event_name].any?
        events[event_name].each do |event|
          event.call(*args)
        end
      end
    end

    def reset_events!
      @events = {}
    end

  private

    def events
      @events ||= {}
    end
  end
end
