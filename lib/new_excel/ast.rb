module NewExcel
  module AST
    class BaseAST
      def initialize(string)
        @string = string
      end

      attr_reader :string

      def value
        raise NotImplementedError, "must implement value in base classes"
      end
    end

    class FunctionCall < BaseAST
      attr_accessor :name
      attr_accessor :arguments

      def value
        evaluated_arguments = arguments.map(&:value)
        NewExcel::BuiltInFunctions.public_send(name, *evaluated_arguments)
      end
    end

    class CellReference < BaseAST
      attr_accessor :sheet_name
      attr_accessor :cell_name

      def value
        file_path = ::File.join($context_file_path, "#{sheet_name}.csv")
        NewExcel::Data.new(file_path, 'csv').evaluate(cell_name)
      end
    end

    class PrimitiveInteger < BaseAST
      def value
        string.to_i
      end
    end

    class PrimitiveFloat < BaseAST
      def value
        string.to_f
      end
    end

    class QuotedString < BaseAST
      def value
        string[1..string.length-2]
      end
    end

    class UnquotedString < BaseAST
      def value
        string
      end
    end

    class DateTime < BaseAST
      def value
        Chronic.parse(string, hours24: true, guess: :begin)
      end
    end
  end
end
