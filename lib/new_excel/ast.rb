module NewExcel
  module AST
    class AstBase; end

    class KeyValuePair < AstBase
      attr_reader :key
      attr_reader :value

      def initialize(key, value)
        @key = key
        @value = value
      end

      def for_printing
        "#{key}:\n#{value}"
      end
    end

    class FunctionCall < AstBase
      attr_reader :name
      attr_reader :arguments

      def initialize(name, arguments=[])
        @name = name
        @arguments = arguments
      end

      def for_printing
        "#{name}(#{arguments.map(&:for_printing).join(", ")})"
      end
    end

    class Function < AstBase
      def initialize(formal_arguments, body)
        @formal_arguments = formal_arguments
        @body = body
        @body = [body] if !body.is_a?(Array)
      end

      attr_reader :formal_arguments
      attr_reader :body

      def for_printing
        "= #{body.map(&:for_printing).join("\n")}"
      end
    end

    class FileReference < AstBase
      def initialize(file_reference, symbol)
        @file_reference = file_reference
        @symbol = symbol
      end

      attr_reader :file_reference
      attr_reader :symbol

      def for_printing
        "#{file_reference}.#{symbol}"
      end
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
        key, value = pair.key, pair.value

        if @hash.has_key?(key)
          raise "Map already has key: #{key}"
        end

        @hash[key] = value
      end
    end

    class Primitive < AstBase
      def initialize(str)
        @string = str
      end

      attr_reader :value
      attr_reader :string

      def for_printing
        @string
      end
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

      def for_printing
        "\"#{@string}\""
      end
    end
  end
end
