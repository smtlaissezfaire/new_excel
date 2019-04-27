module NewExcel
  module Runtime
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

    class Symbol < AstBase
      def initialize(str)
        @str = str
        @symbol = str.to_sym
      end

      attr_reader :symbol
    end

    class Primitive < AstBase
      def initialize(str)
        @str = str
      end

      attr_reader :value
    end

    class PrimitiveInteger < Primitive
      def initialize(str)
        @value = str.to_i
      end
    end

    class PrimitiveFloat < Primitive
      def initialize(str)
        @value = str.to_f
      end
    end

    class Boolean < Primitive
      def initialize(str)
        @value = (str == true || str == "true")
      end
    end

    class String < Primitive
      def initialize(str)
        @str = str
        @value = str
      end
    end
  end
end
