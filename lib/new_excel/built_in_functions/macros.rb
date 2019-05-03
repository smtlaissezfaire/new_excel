module NewExcel
  module BuiltInFunctions
    module Macros
      def if(*args)
        conds, truthy_expressions, falsy_expressions = args

        zipped_lists([_evaluate(conds), truthy_expressions, falsy_expressions]) do |cond, truthy_expression, falsy_expression|
          cond ? _evaluate(truthy_expression) : _evaluate(falsy_expression)
        end
      end

      def and(expressions)
        values = []
        got_false_value = false

        expressions.each do |expression|
          if got_false_value
            values << false
          else
            res = evaluate(expression)
            got_false_value = true if !res
            values << res
          end
        end

        zipped_lists(values) do |list|
          # list.all?
          list.all?
        end
      end

      def or(*list)
        zipped_lists(list) do |list|
          val = nil
          list.map do |obj|
            val = _evaluate(obj)
            break if val
          end
          val
        end
      end
    end
  end
end
