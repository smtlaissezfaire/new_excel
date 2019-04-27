module NewExcel
  module Runtime
    def self.base_environment
      env = {}

      mod = NewExcel::BuiltInFunctions
      mod.public_instance_methods.each do |method_name|
        env[method_name] = mod.method(method_name)
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

  module NewAST
    class AstBase; end

    class KeyValuePair < AstBase
      attr_reader :key
      attr_reader :value

      def initialize(key, value)
        @key = key
        @value = value
      end
    end

    class FunctionCall < AstBase
      attr_reader :name
      attr_reader :arguments

      def initialize(name, arguments=[])
        @name = name
        @arguments = arguments
      end
    end

    class Function < AstBase
      def initialize(formal_arguments, body)
        @formal_arguments = formal_arguments
        @body = body
      end

      attr_reader :formal_arguments
      attr_reader :body
    end

    class FileReference < AstBase
      def initialize(file_reference, symbol)
        @file_reference = file_reference
        @symbol = symbol
      end

      attr_reader :file_reference
      attr_reader :symbol
    end

    class Symbol < AstBase
      def initialize(str)
        @str = str
        @symbol = str.to_sym
      end

      attr_reader :symbol
    end

    class Map < AstBase
      def initialize(hash={})
        @hash = hash
      end

      def to_hash
        @hash
      end

      def add_pair(pair)
        @hash[pair.key] = pair.value
      end
    end

    class Primitive < AstBase
      def initialize(str)
        @string = str
      end

      attr_reader :value
      attr_reader :string
    end

    class PrimitiveInteger < Primitive
      def initialize(str)
        super
        @value = str.to_i
      end
    end

    class PrimitiveFloat < Primitive
      def initialize(str)
        super
        @value = str.to_f
      end
    end

    class Boolean < Primitive
      def initialize(str)
        super
        @value = (str == true || str == "true")
      end
    end

    class String < Primitive
      def initialize(str)
        super
        @value = str
      end
    end
  end
end
