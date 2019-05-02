module NewExcel
  module BuiltInFunctions
    module Primitives
      # primitives

      def primitive_method_call(obj, method, arguments=[])
        obj.public_send(method, *arguments)
      end

      def primitive_infix(method, val1, val2)
        primitive_method_call(val1, method, [val2])
      end
    end
  end
end
