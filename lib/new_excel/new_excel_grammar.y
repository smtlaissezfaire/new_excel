class NewExcelGrammarParser
rule
  root: formula |
    primitive

  formula: EQ formula_body { result = val[1] }

  formula_body: function_call | remote_cell_reference | primitive_value

  function_call: ID OPEN_PAREN function_body CLOSE_PAREN {
    ref = NewExcel::AST::FunctionCall.new(val.join)
    ref.name = val[0]
    ref.arguments = Array(val[2]).compact.flatten
    result = ref
  }

  function_body:
    |
    function_arguments { result = val }

  function_arguments:
    function_arguments COMMA function_argument  { result = [val[0], val[2]] } |
    function_argument { result = val[0] }

  function_argument: function_call | remote_cell_reference | primitive_value

  remote_cell_reference:
    ID DOT ID {
      ref = NewExcel::AST::CellReference.new(val.join)
      ref.sheet_name = val[0]
      ref.cell_name = val[2]
      result = ref
    }

  primitive_value: quoted_string | datetime | integer | float

  # there must be a better way?
  primitive:
    primitive any_primitive_type {
      strings = val.map do |v|
        v.respond_to?(:string) ? v.string : v
      end

      result = NewExcel::AST::UnquotedString.new(strings.join)
    } |
    any_primitive_type {
      ref = if val[0].is_a?(NewExcel::AST::BaseAST)
        val[0]
      else
        NewExcel::AST::UnquotedString.new(val.join)
      end

      result = ref
    }

  any_primitive_type: datetime | float | integer | TEXT

  quoted_string: QUOTED_STRING { result = NewExcel::AST::QuotedString.new(val[0]) }
  datetime: DATE_TIME { result = NewExcel::AST::DateTime.new(val[0]) }
  float: FLOAT { result = NewExcel::AST::PrimitiveFloat.new(val[0]) }
  integer: INTEGER { result = NewExcel::AST::PrimitiveInteger.new(val[0]) }
end

---- inner

  def parse(str)
    @q = NewExcel::Parser.get_tokens(str)
    do_parse
  end

  def next_token
    @q.shift
  end

  def on_error(*args)
    $stderr.puts "on_error called: args=#{args.inspect}"
    super
  end
