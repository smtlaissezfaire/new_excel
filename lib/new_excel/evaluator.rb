module NewExcel
  class Evaluator
    # def self.evaluate(*args)
    #   new(*args).evaluate
    # end
    #
    # def self.parser
    #   @parser = Parser.new
    # end
    #
    # def initialize(context, str)
    #   @context = context
    #   @str = str
    # end
    #
    # attr_reader :container_file_path
    #
    # def parser
    #   self.class.parser
    # end
    #
    # def evaluate
    #   if @str.is_a?(Array)
    #     @str.map do |el|
    #       self.class.evaluate(self, el)
    #     end
    #   elsif @str.is_a?(String)
    #     ast = parser.parse(@str)
    #     ast.value
    #   else
    #     raise "unknown parsing type!"
    #   end
    # end
  end
end
