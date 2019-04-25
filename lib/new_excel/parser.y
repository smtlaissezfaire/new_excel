class NewExcel::Parser
rule
  root: assignments | value

  assignments: assignments assignment {
    ref = val[0]
    ref.add_pair(val[1])
    result = ref
  } |
  assignment {
    ref = AST::Map.new(val.join)
    ref.add_pair(val[0])
    result = ref
  }

  assignment: KEY_WITH_COLON value {
    ref = AST::KeyValuePair.new(val.join)
    key_with_colon = val[0]
    key_without_colon = key_with_colon[0..(key_with_colon.length-2)]

    ref.hash_key = key_without_colon
    ref.hash_value = val[1]
    result = ref
  }

  value: function_definition | primitive

  function_definition:
    OPEN_PAREN formal_function_arguments CLOSE_PAREN formula {
      function = val[3]
      function.arguments = val[1]
      result = function
    } |
    formula

  formal_function_arguments:
    |
    formal_function_argument COMMA formal_function_arguments  { result = [val[0], val[2]].flatten } |
    formal_function_argument { result = [val[0]] }

  formal_function_argument: ID {
    arg = AST::FunctionFormalArgument.new(val[0])
    arg.name = val[0]
    result = arg
  }

  formula: EQ formula_body {
    ref = AST::Function.new(val.join)
    ref.body = val[1]
    result = ref
  }

  formula_body: expression

  expression: function_call | cell_reference | primitive_value

  function_call: ID OPEN_PAREN function_body CLOSE_PAREN {
    ref = AST::FunctionCall.new(val.join)
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

  function_argument: expression

  cell_reference: remote_cell_reference | local_cell_reference

  remote_cell_reference:
    ID DOT ID {
      ref = AST::CellReference.new(val.join)
      ref.sheet_name = val[0]
      ref.cell_name = val[2]
      result = ref
    }

  local_cell_reference:
    ID {
      ref = AST::CellReference.new(val.join)
      ref.cell_name = val[0]
      result = ref
    }

  primitive_value: quoted_string | datetime | time | integer | float | boolean

  # there must be a better way?
  primitive: primitive any_primitive_type {
    string = ""

    strings = val.map do |v|
      str = v.respond_to?(:string) ? v.string : v
      str = "#{str} " if v.is_a?(AST::UnquotedStringIdFallThrough)
      string << str
    end

    string = string.strip

    result = AST::UnquotedString.new(string)
  }
  | any_primitive_type {
    ref = if val[0].is_a?(AST::BaseAST)
      val[0]
    else
      AST::UnquotedString.new(val.join)
    end

    result = ref
  }

  any_primitive_type: datetime | time | float | integer | boolean | id_primitive_fall_through | text

  quoted_string: QUOTED_STRING { result = AST::QuotedString.new(val[0]) }
  datetime: DATE_TIME { result = AST::DateTime.new(val[0]) }
  time: TIME { result = AST::UnquotedString.new(val[0]) } # TODO!
  float: FLOAT { result = AST::PrimitiveFloat.new(val[0]) }
  integer: INTEGER { result = AST::PrimitiveInteger.new(val[0]) }
  id_primitive_fall_through: ID { result = AST::UnquotedStringIdFallThrough.new(val[0]) }
  text: TEXT { result = AST::UnquotedString.new(val[0]) }
  boolean: BOOLEAN { result = AST::Boolean.new(val[0]) }
end

---- inner

  def parse(str)
    @q = Tokenizer.get_tokens(str)
    do_parse
  end

  def next_token
    @q.shift
  end

  def on_error(*args)
    $stderr.puts "on_error called: args=#{args.inspect}"
    super
  end
