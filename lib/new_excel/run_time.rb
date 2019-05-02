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

      # TODO: shouldn't need to use keys mapped to functions mapped to lambdas
      sheet_env = sheet.default_environment(minimal_env)

      sheet_env.dup
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
