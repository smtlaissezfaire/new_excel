module NewExcel
  class Evaluator
    def evaluate(expr, env = {})
      case expr
      when Array
        function_name = car(expr)

        case function_name
        when :lambda
          Runtime::Closure.new(expr[1], expr[2], env)
        when :define
          env[expr[1]] = evaluate(expr[2], env)
        when :if
          eval_if(cdr(expr), env)
        when :quote
          quote(expr[1])
        when :hash_map
          hash_map(cdr(expr))
        else
          fn = evaluate(function_name, env)
          raise "Can't find function with name: #{function_name.inspect}" unless fn

          apply(fn,
                evaluate_list(cdr(expr), env),
                env)
        end
      when Symbol
        lookup(expr, env)
      when Hash
        expr
      when Integer, Float, TrueClass, FalseClass, String
        expr
      when NewAST::AstBase
        evaluate(quote(expr), env)
      else
        raise "Unknown expression type!, expr: #{expr.inspect}"
      end
    end

    def evaluate_list(list, env)
      list.map do |item|
        evaluate(item, env)
      end
    end

    def eval_if(clauses, env)
      cond, true_expr, false_expr = clauses

      if evaluate(cond, env)
        evaluate(true_expr, env)
      else
        evaluate(false_expr, env)
      end
    end

    def lookup(expr, env)
      env[expr]
    end

    def apply(fn, arguments, env)
      if primitive_function?(fn)
        apply_primitive(fn, arguments, env)
      else
        evaluate(fn.body, bind(fn.formal_arguments, arguments, env))
      end
    end

    def bind(formal_arguments, evaluated_arguments, env)
      new_env = {}

      formal_arguments.zip(evaluated_arguments) do |l1, l2|
        new_env[l1] = l2
      end

      env.merge(new_env)
    end

    def primitive_function?(fn)
      fn.is_a?(Proc) || fn.is_a?(Method) || fn.is_a?(UnboundMethod)
    end

    def apply_primitive(fn, arguments, env)
      fn.call(*arguments)
    end

    def car(list)
      list[0]
    end

    def cdr(list)
      list.slice(1, list.length)
    end

    def quote(obj)
      case obj
      when Symbol, Array, Integer, Float, TrueClass, FalseClass, String
        obj
      when NewAST::Symbol
        obj.symbol
      when NewAST::Primitive
        obj.value
      when NewAST::Function
        [:lambda, quote(obj.formal_arguments)] + quote_list(obj.body)
      when NewAST::FunctionCall
        [quote(obj.name)] + quote_list(obj.arguments)
      when NewAST::KeyValuePair
        [:define, quote(obj.key), quote(obj.value)]
      when NewAST::FileReference
        [:lookup, quote(obj.symbol), [:lookup_environment, quote(obj.file_reference)]]
      when NewAST::Map
        [:hash_map, quote_list(obj.to_hash.to_a)]
      else
        raise "Not sure how to quote: #{obj.inspect}"
      end
    end

    def quote_list(lst)
      lst.map { |l| quote(l) }
    end

    def hash_map(args)
      Hash[*args]
    end
  end
end
