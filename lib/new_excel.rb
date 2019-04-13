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

          if @column_names.include?(column_name)
            raise "Duplicate column name: #{column_name.inspect}"
          end

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
      $context_file_path = @file_path # code smell!
    end

    attr_reader :file_path

    def evaluate
      if @str.is_a?(Array)
        @str.map do |el|
          self.class.evaluate(self, el)
        end
      elsif @str.is_a?(String)
        Parser.new.parse(@str)
      else
        raise "unknown parsing type!"
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

    def evaluate(*args)
      Evaluator.evaluate(self, get(*args))
    end
  end

  require 'treetop'
  require 'byebug'

  Treetop.load File.join(File.expand_path(File.dirname(__FILE__)), 'grammar')

  class Parser
    def parse(str)
      parser = MyGrammarParser.new
      res = parser.parse(str)

      # pp parser.inspect

      if res
        res.evaluate
      else
        pp parser.inspect
        raise parser.failure_reason
      end
    end

    alias_method :evaluate, :parse
  end
end
