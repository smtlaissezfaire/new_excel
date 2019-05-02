module NewExcel
  module Runtime
    def self.base_environment
      env = {}

      mod = NewExcel::Evaluator
      mod.public_instance_methods.each do |method_name|
        env[method_name] = mod.instance_method(method_name)
      end

      file_path = ::File.dirname(__FILE__)
      file = NewExcel::File.new(file_path)
      sheet = file.get_sheet("built_in_functions")
      sheet.parse

      sheet.ast.map.to_hash.each do |key, value|
        env[key] = value
      end

      env.dup
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
