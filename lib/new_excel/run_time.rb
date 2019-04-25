module NewExcel
  module RunTime
    class Environment
      attr_accessor :parent

      def initialize
        @hash = {}
        @parent = nil
      end

      def to_hash
        val ||= @hash.dup
        val = val.merge(parent.to_hash) if parent
        val
      end

      def [](key)
        key = key.to_sym
        val ||= @hash[key]
        val ||= parent[key] if parent
        val
      end

      def []=(key, value)
        @hash[key.to_sym] = value
      end

      def keys
        to_hash.keys
      end
    end
  end
end
