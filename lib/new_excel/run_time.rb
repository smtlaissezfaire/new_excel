module NewExcel
  module Runtime
    def self.base_environment
      @base_environment ||= Environment.base
    end

    class Environment
      class << self
        def base
          @base ||= begin
            minimal_env = NewExcel::Runtime::Environment.new

            mod = NewExcel::Evaluator
            mod.public_instance_methods.each do |method_name|
              minimal_env.define(method_name, mod.instance_method(method_name))
            end

            file_path = ::File.join(::File.dirname(__FILE__), "stdlib")
            file = NewExcel::File.new(file_path)

            [
              "list",
              "math",
              "logical",
            ].each do |sheet|
              sheet = file.get_sheet(sheet)
              sheet.evaluate_as_hash_map_without_evaluating_columns(minimal_env)
            end

            minimal_env
          end
        end
      end

      def initialize(hash = {}, parent = nil)
        @hash = hash
        @parent = parent
        @lookup_cache = {}
      end

      def set!(key, value)
        if @hash.has_key?(key)
          @hash[key] = value
        elsif @parent
          @parent.set!(key, value)
        end
      end

      def define(key, value)
        @hash[key] = value
      end

      def get(key)
        if @hash.has_key?(key)
          @hash[key]
        elsif @parent
          @parent.get(key)
        else
          raise "Couldn't find variable: #{key.inspect}"
        end
      end

      def lookup(expr, evaluator)
        if @hash.has_key?(expr)
          val = @hash[expr]

          if val.is_a?(NewExcel::AST::Function)
            @lookup_cache[expr] ||= if val.formal_arguments == []
              evaluator.evaluate([val])
            else
              evaluator.evaluate(val)
            end
          else
            val
          end
        elsif @parent
          @parent.lookup(expr, evaluator)
        else
          raise "Couldn't lookup: #{expr.inspect}"
        end
      end

      def inspect
        "#<#{self.class}:#{object_id} direct_keys: #{@hash.keys.inspect}, parent: #{@parent.inspect}>"
      end

      def to_hash(include_children = true)
        hash = @hash.dup

        if include_children && @parent
          hash = @parent.to_hash.merge(hash)
        end

        hash
      end

      def merge(hash)
        self.class.new(hash.to_hash, self)
      end

      def keys
        to_hash.keys
      end
    end

    class Closure
      def initialize(formal_arguments, body, env)
        @formal_arguments = formal_arguments
        @body = body
        @env = Environment.new({}, env)
      end

      attr_reader :formal_arguments
      attr_reader :body
      attr_reader :env
    end
  end
end
