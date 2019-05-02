module NewExcel
  module BuiltInFunctions
    module Sheets
      def column(name)
        reference = AST::CellReference.new("dynamic cell reference")
        reference.cell_name = name
        reference.value
      end

      alias_method :c, :column
    end
  end
end
