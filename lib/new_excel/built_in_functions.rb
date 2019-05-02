module NewExcel
  module BuiltInFunctions
    include ListHelpers
    include NewExcel::BuiltInFunctions::Primitives
    include NewExcel::BuiltInFunctions::Macros
    include NewExcel::BuiltInFunctions::Evaluator
    include NewExcel::BuiltInFunctions::Functions
    include NewExcel::BuiltInFunctions::Equality
    include NewExcel::BuiltInFunctions::List
    include NewExcel::BuiltInFunctions::Math
    include NewExcel::BuiltInFunctions::String
    include NewExcel::BuiltInFunctions::DateTime
    include NewExcel::BuiltInFunctions::Sheets

    extend self
  end
end
