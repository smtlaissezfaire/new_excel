module NewExcel
  class Evaluator
    def self.evaluate(*args)
      new(*args).evaluate
    end

    def self.parser
      @parser = Parser.new
    end

    def initialize(context, str)
      @context = context
      @str = str
      @file_path = context.respond_to?(:file_path) ? context.file_path : "" # code smell - should be global-ish!
      $context_file_path = @file_path # code smell!
    end

    attr_reader :file_path

    def parser
      self.class.parser
    end

    def evaluate
      if @str.is_a?(Array)
        @str.map do |el|
          self.class.evaluate(self, el)
        end
      elsif @str.is_a?(String)
        ast = parser.parse(@str)
        ast.value
      else
        raise "unknown parsing type!"
      end
    end
  end
end
