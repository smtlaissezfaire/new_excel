require "new_excel/version"

require 'time'

module NewExcel
  class Map
    def initialize(file)
      @file = file
      @file_path = File.dirname(@file)
      @column_names = []
      @values = {}
      parse!
    end

    attr_reader :file_path

    def parse!
      last_column_name = nil

      raw_map.each_line do |line|
        if line =~ /^[A-Za-z0-9]/
          column_name = line.gsub(/\:$/, '').strip
          @column_names << column_name
          @values[column_name] ||= ""
          last_column_name = column_name
        elsif last_column_name
          @values[last_column_name] << line
        end
      end

      @values.each do |key, value|
        value.strip!
      end
    end

    attr_reader :column_names
    alias_method :columns, :column_names

    def raw_map
      @raw_map ||= File.read(@file)
    end

    def get(column_name)
      raise "Column #{column_name.inspect} not found!" if !@values.has_key?(column_name)
      @values[column_name]
    end

    alias_method :raw_value_for, :get

    def evaluate(column_name, index = nil)
      val = Evaluator.evaluate(self, get(column_name))

      if index
        val[index-1]
      else
        val
      end
    end
  end

  require 'chronic'

  module BuiltInFunctions
    extend self

    def subtract(n1, n2)
      n1 - n2
    end

    def add(n1, n2)
      n1 + n2
    end
  end

  class Evaluator
    def self.evaluate(*args)
      new(*args).evaluate
    end

    def initialize(context, str)
      @context = context
      @str = str
      @file_path = context.file_path # code smell - should be global-ish!
    end

    attr_reader :file_path

    def evaluate
      if @str.is_a?(Array)
        @str.map do |el|
          self.class.evaluate(self, el)
        end
      elsif @str.is_a?(String)
        if @str =~ /\=\s*([a-zA-Z\_]+)\((.*)\)/ # assume it's a function
          fn = $1
          args = $2.split(",").map { |r| r.strip }

          evaluated_values = args.map do |arg|
            Evaluator.evaluate(self, "= #{arg}")
          end

          new_map = []

          evaluated_values[0].each_with_index do |_, index|
            new_map << BuiltInFunctions.public_send(fn, *evaluated_values.map { |x| x[index] })
          end

          new_map
        elsif @str =~ /\=(.*)/
          file, column = $1.split(".")
          # NewExcel::Map.new(context.file_path)
          file_path = File.join(@file_path, "#{file.strip}.csv")
          Data.new(file_path, 'csv').evaluate(column)
        else
          if @str =~ /^[0-9\.]+$/
            Float(@str)
          elsif @str =~ /^[0-9]+$/
            Integer(@str)
          elsif (@str =~ /\d/ && @str =~ /\// || @str =~ /\-/) && date = Chronic.parse(@str, hours24: true, guess: :begin)
            date
          else
            @str
          end
        end
      end
    end
  end

  require 'csv'

  class Data
    def initialize(file_path, type)
      @file = file_path
      @file_path = File.dirname(@file)
      parse
    end

    attr_reader :file_path

    def raw_map
      @raw_map ||= File.read(@file)
    end

    def parse
      @parsed_file ||= CSV.parse(raw_map)
      @columns = @parsed_file.shift
      @all_rows = @parsed_file
    end

    def columns
      @columns
    end

    def get(val=nil)
      if val.is_a?(String) || val.is_a?(Integer)
        index = if val.is_a?(String)
          @columns.index(val)
        else
          val-1
        end

        @all_rows.map do |line|
          line[index]
        end
      elsif val.is_a?(Hash) || val.nil?
        array = []
        if val && val[:with_header]
          array << @columns
        end
        array += @all_rows
        array
      end
    end

    # make this simpler
    def evaluate(*args)
      Evaluator.evaluate(self, get(*args))
    end
  end
end
