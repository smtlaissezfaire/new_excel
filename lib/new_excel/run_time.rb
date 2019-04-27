module NewExcel
  module Runtime
    def self.base_environment
      env = {}

      mod = NewExcel::BuiltInFunctions
      mod.public_instance_methods.each do |method_name|
        env[method_name] = mod.method(method_name)
      end

      mod = NewExcel::Evaluator
      mod.public_instance_methods.each do |method_name|
        env[method_name] = mod.instance_method(method_name)
      end

      env.dup
    end

    class Closure
      def initialize(formal_arguments, body, env)
        @formal_arguments = formal_arguments
        @body = body
        @env = env
      end

      attr_reader :formal_arguments
      attr_reader :body
    end
  end
end
