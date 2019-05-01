class NewExcel::Parser
rule
  root: expressions {
    statement_list = AST::StatementList.new
    statement_list.statements = val.flatten
    result = statement_list
  }

  expressions:
    expression expressions { result = [val[0], val[1]] } |
    expression

  expression:
    assignment | function_call | function_definition | cell_reference | primitive

  assignment:
    KEY_WITH_COLON expression {
      key_with_colon = val[0]
      key_without_colon = key_with_colon[0..(key_with_colon.length-2)].strip

      hash_key = key_without_colon.to_sym
      hash_value = val[1]

      result = AST::KeyValuePair.new(hash_key, hash_value)
    }

  function_call:
    function_reference OPEN_PAREN optional_function_arguments CLOSE_PAREN {
      function_reference = val[0]
      arguments = Array(val[2]).compact.flatten

      result = AST::FunctionCall.new(function_reference, arguments)
    }

  function_reference:
    OPEN_PAREN function_definition CLOSE_PAREN { result = AST::FunctionReference.new(val[1]) } |
    function_definition                        { result = AST::FunctionReference.new(val[0]) } |
    ID                                         { result = AST::FunctionReference.new(val[0]) }

  optional_function_arguments:
    |
    function_arguments { result = val }

  function_arguments:
    function_arguments COMMA function_argument  { result = [val[0], val[2]] } |
    function_argument { result = val[0] }

  function_argument: expression

  function_definition:
    OPEN_PAREN formal_function_arguments CLOSE_PAREN formula {
      formal_arguments = val[1] || []
      body = val[3]

      result = AST::Function.new(formal_arguments, body)
    } |
    formula {
      body = [val[0]]
      result = AST::Function.new([], body)
    }

  formal_function_arguments:
    |
    formal_function_argument COMMA formal_function_arguments  { result = [val[0], val[2]].flatten } |
    formal_function_argument { result = [val[0]] }

  formal_function_argument:
    ID {
      result = AST::Symbol.new(val[0].to_sym)
    }

  formula:
    EQ expression {
      result = val[1]
    }

  cell_reference: remote_cell_reference | local_cell_reference

  remote_cell_reference:
    ID DOT ID {
      result = AST::FileReference.new(val[0].to_sym, val[2].to_sym)
    }

  local_cell_reference:
    ID {
      result = AST::Symbol.new(val[0].to_sym)
    }

  primitive: quoted_string | float | integer | boolean

  quoted_string: QUOTED_STRING {
    string = val[0]
    string = string[1..string.length-2]
    result = AST::String.new(string)
  }
  float: FLOAT { result = AST::PrimitiveFloat.new(val[0]) }
  integer: INTEGER { result = AST::PrimitiveInteger.new(val[0]) }
  boolean: BOOLEAN { result = AST::Boolean.new(val[0]) }
end

---- inner

  def parse(str)
    # set to true for debugging
    # http://i.loveruby.net/en/projects/racc/doc/debug.html
    @yydebug=false
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
