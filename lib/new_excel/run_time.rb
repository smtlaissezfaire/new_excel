module NewExcel
  module Runtime
    def self.base_environment
      minimal_env = {}

      mod = NewExcel::Evaluator
      mod.public_instance_methods.each do |method_name|
        minimal_env[method_name] = mod.instance_method(method_name)
      end

      file_path = ::File.dirname(__FILE__)
      file = NewExcel::File.new(file_path)
      sheet = file.get_sheet("built_in_functions")

      sheet.parse

      # TODO: shouldn't this be the same as sheet.evaluated_with_unevaluated_columns ?
      evaluator = Evaluator.new

      sheet.statements.each do |statement|
        sheet.evaluate(statement, minimal_env)
      end

      map_hash = sheet.ast.map.to_hash

      map_hash.each do |key, value|
        evaluator.evaluate(key, minimal_env)
      end

      minimal_env
    end

    class Closure
      def initialize(formal_arguments, body, env)
        @formal_arguments = formal_arguments
        @body = body
        @env = env.dup
      end

      attr_reader :formal_arguments
      attr_reader :body
      attr_reader :env
    end
  end
end
