class NewExcel::NewParser
rule
  root: assignments | expression | value

  assignments:
    assignments assignment {
      ref = val[0]
      ref.add_pair(val[1])
      result = ref
    } |
    assignment {
      ref = NewAST::Map.new()
      ref.add_pair(val[0])
      result = ref
    }

  assignment:
    KEY_WITH_COLON value {
      key_with_colon = val[0]
      key_without_colon = key_with_colon[0..(key_with_colon.length-2)]

      hash_key = key_without_colon.to_sym
      hash_value = val[1]

      result = NewAST::KeyValuePair.new(hash_key, hash_value)
    }

  value: function_definition | primitive

  function_definition:
    OPEN_PAREN formal_function_arguments CLOSE_PAREN formula {
      formal_arguments = val[1] || []
      body = val[3]

      result = NewAST::Function.new(formal_arguments, body)
    } |
    formula {
      result = NewAST::Function.new([], val[0])
    }

  formal_function_arguments:
    |
    formal_function_argument COMMA formal_function_arguments  { result = [val[0], val[2]].flatten } |
    formal_function_argument { result = [val[0]] }

  formal_function_argument:
    ID {
      result = NewAST::Symbol.new(val[0].to_sym)
    }

  formula:
    EQ formula_body {
      result = val[1]
    }

  formula_body: expression

  expression: function_call | cell_reference | primitive

  function_call:
    ID OPEN_PAREN function_body CLOSE_PAREN {
      name = val[0].to_sym
      arguments = Array(val[2]).compact.flatten

      result = NewAST::FunctionCall.new(name, arguments)
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
      result = NewAST::FileReference.new(val[0].to_sym, val[2].to_sym)
    }

  local_cell_reference:
    ID {
      result = NewAST::Symbol.new(val[0].to_sym)
    }

  primitive: quoted_string | float | integer | boolean

  quoted_string: QUOTED_STRING {
    string = val[0]
    string = string[1..string.length-2]
    result = NewAST::String.new(string)
  }
  float: FLOAT { result = NewAST::PrimitiveFloat.new(val[0]) }
  integer: INTEGER { result = NewAST::PrimitiveInteger.new(val[0]) }
  boolean: BOOLEAN { result = NewAST::Boolean.new(val[0]) }
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
