
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "new_excel/version"

Gem::Specification.new do |spec|
  spec.name          = "new_excel"
  spec.version       = NewExcel::VERSION
  spec.authors       = ["Scott Taylor"]
  spec.email         = ["scott@railsnewbie.com"]

  spec.summary       = %q{New Excel}
  spec.description   = %q{New Excel}
  # spec.homepage      = "Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]


  spec.add_dependency 'chronic'
  spec.add_dependency 'racc'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'memoist'
  spec.add_dependency 'terminal-table'
  spec.add_dependency 'colored'
  spec.add_dependency 'curses'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'rspec-autotest'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'fakefs'

  # spec.add_development_dependency "bundler", "~> 1.16"
  # spec.add_development_dependency "rake", "~> 10.0"
  # spec.add_development_dependency "rspec", "~> 3.0"
  # spec.add_development_dependency "rspec-autotest", "~> 3.0"
end
