require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => [:compile, :spec]

task :compile_parser do
  `bundle exec racc lib/new_excel/parser.y -o lib/new_excel/parser.rb`
end

task :compile => [:compile_parser]
task :c => [:compile]

task :clean do
  `rm -rf lib/new_excel/parser.rb`
end
