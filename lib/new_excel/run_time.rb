module NewExcel
  module Runtime
    def self.base_environment
      minimal_env = {}

      mod = NewExcel::Evaluator
      mod.public_instance_methods.each do |method_name|
        minimal_env[method_name] = mod.instance_method(method_name)
      end

      file_path = ::File.join(::File.dirname(__FILE__), "stdlib")
      file = NewExcel::File.new(file_path)

      [
        "list",
        "math"
      ].each do |sheet|
        sheet = file.get_sheet(sheet)
        sheet.evaluate_as_hash_map_without_evaluating_columns(minimal_env)
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
