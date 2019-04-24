module NewExcel
  class Sheet
    include ListHelpers

    def initialize(file_path)
      @sheet_file_path = file_path
      @container_file_path = ::File.dirname(@sheet_file_path)
      @column_names = []
    end

    attr_reader :container_file_path

    def sheet_name
      ::File.basename(@sheet_file_path, ::File.extname(@sheet_file_path)).to_s
    end

    def column_names
      parse
      @column_names
    end

    alias_method :columns, :column_names

    def raw_content
      @raw_content ||= ::File.read(@sheet_file_path)
    end

    def raw_value_for(*a, &b)
      get(*a, &b)
    end

    def parse
      raise NotImplementedError, "must be implemented in subclasses"
    end

    #
    # TBD: implement this generically...
    #
    # ***DESIRED*** interface:
    #
    # get = all unevaluated content
    # get() = all columns
    # get(col1, col2, col3)
    # get(1) => col 1
    # get(1, 2) => row 1, col 2
    # get(column_name, 2) => col with column_name, row 2
    # get([col1, col2], 2) => col1 + col2, both with only row 2
    # get(with_header: true) # include the headers
    # get(col1, with_header: true)
    def get(*a, &b)
      raise NotImplementedError, "must be implemented in subclasses"
    end

    def filter(*args)
      parse

      set_process_state do
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:with_header] = false unless options[:with_header]

        if args && args.any?
          if args.length >= 2 && (args.last.is_a?(Integer) || args.last.is_a?(Array))
            row_indexes = args.pop
            row_indexes = [row_indexes] if !row_indexes.is_a?(Array)
            options[:only_rows] = row_indexes
          end

          options[:only_columns] = args.flatten
        end

        @ast.value(options)
      end
    end

    alias_method :read, :filter

    def get_column(column)
      filter(column).map(&:first)
    end

    def print
      Kernel.print for_printing
    end

    # def ncurses_print
    #   # data = for_printing
    #   # # debugger
    #   # lines = data.split("\n")
    #   #
    #   # Curses.init_screen
    #   #
    #   # height = Curses.lines
    #   # width = lines.map { |line| line.length }.max
    #   #
    #   # window = Curses::Window.new(height, width, 0, 0)
    #   # window.setpos(0, 0)
    #   # window.addstr("")
    #   # lines.each do |line|
    #   #   window << "#{line}\n"
    #   # end
    #   #
    #   # # window.scrollok = true
    #   #
    #   # # window.refresh
    #   # # window.getch
    #   # # window.close
    #   #
    #   #
    #   #
    #   # # my_str = "LOOK! PONIES!"
    #   # #
    #   # # height, width = 12, my_str.length + 10
    #   # # top, left = (Curses.lines - height) / 2, (Curses.cols - width) / 2
    #   # # bwin = Curses::Window.new(height, width, top, left)
    #   # # bwin.box("\\", "/")
    #   # # bwin.refresh
    #   # #
    #   # # win = bwin.subwin(height - 4, width - 4, top + 2, left + 2)
    #   # # win.setpos(2, 3)
    #   # # win.addstr(my_str)
    #   # # # or even
    #   # # win << "\nOH REALLY?"
    #   # # win << "\nYES!! " + my_str
    #   # # win.refresh
    #   # # win.getch
    #   # # win.close
    # end

    def ncurses_print
      Curses.init_screen
      Curses.start_color
      # Curses.curs_set(0)
      Curses.noecho

      # Curses.init_pair(1, 1, 0)

      begin


        window = Curses::Window.new(10_000, 10_000, 1, 2)
        window.keypad = true
        # window.scrollok true
        window.addstr("Fetching results...")
        window.refresh

        data = for_printing
        split_data = data.split("\n")

#         data = <<-CODE
# Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
# eiusmod tempor incididunt ut labore et dolore magna aliqua.
# Ut enim ad minim veniam, quis nostrud exercitation ullamco
# laboris nisi ut aliquip ex ea commodo consequat. Duis
# aute irure dolor in reprehenderit in voluptate velit esse
#         CODE
        # split_data = data.split("\n")

        window.clear
        window.refresh

        x_position = 0
        y_position = 0

        split_data.each do |line|
          window << line
          Curses.clrtoeol
          window << "\n" # and move to next
        end

        # derwin = window.derwin(0, 0, 0, 0)
        # derwin.refresh

        # subwindow = window.derwin(0, 0, 0, 0)

        window.move(100, 100)
        window.refresh

        loop do
          window.setpos(y_position, x_position)
          # window.move(y_position, x_position)
          # derwin.move_relative(x_position, y_position)
          # derwin.refresh
          # window.box
          # window.box(x_position, y_position)
          # (window.maxy - window.cury).times {window.deleteln()}
          # window.move_relative(y_position, x_position)
          # window.refresh

          # window.scroll
          # window.scrollok(true)
          # window.setscrreg(1, 1)

          chr = window.getch

          case chr
          when Curses::KEY_UP
            y_position = y_position - 1
            y_position = 0 if y_position < 0

            window.scrl(-1)
          when Curses::KEY_DOWN
            y_position = y_position + 1
            window.scrl(1)
          when Curses::KEY_LEFT
            x_position = x_position - 1
            x_position = 0 if x_position < 0
          when Curses::KEY_RIGHT
            x_position = x_position + 1
          when 'q'
            # window.clear
            # window.addstr("Quitting")
            exit
          else
            raise "got here, chr: #{chr}"
          end
        end
      ensure
        Curses.close_screen
      end
    end

    def for_printing(*args)
      all_values = filter(*args)

      column_names_for_display = column_names

      if ProcessState.use_colors
        column_names_for_display = column_names.map(&:blue).map(&:bold)
      end

      str = ::Terminal::Table.new({
        style: {
          border_top: false,
          border_bottom: false,
          border_y: ' ',
          border_i: ' ',
        },
        headings: column_names_for_display,
        rows: all_values,
      }).to_s

      str + "\n"
    end

  private

    def parser
      @parser ||= Parser.new
    end

    def set_process_state
      old_file_path = NewExcel::ProcessState.current_file_path
      old_sheet = NewExcel::ProcessState.current_sheet

      NewExcel::ProcessState.current_file_path = @container_file_path
      NewExcel::ProcessState.current_sheet = self

      yield
    ensure
      NewExcel::ProcessState.current_file_path = old_file_path
      NewExcel::ProcessState.current_sheet = old_sheet
    end
  end
end
