# very helpful:
# https://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html
class NewExcel::DependencyResolver
  class CircularDependencyError < StandardError; end

  def initialize
    @dependencies = {}
    @resolutions = {}
  end

  attr_reader :dependencies

  def add_dependency(a, b)
    @resoluion_cache = {}

    @dependencies[a] ||= []
    @dependencies[a] << b
  end

  def resolve(node)
    resolve_with_original(node) - [node]
  end

  def resolve_with_original(node, resolved=[], seen=[])
    @resoluion_cache[node] ||= begin
      seen << node

      edges = dependencies[node] || []

      edges.each do |edge|
        if !resolved.include?(edge)
          if seen.include?(edge)
            raise CircularDependencyError, "Circular reference detected: #{node} -> #{edge}"
          end

          resolve_with_original(edge, resolved, seen)
        end
      end

      resolved << node
      resolved
    end
  end
end
