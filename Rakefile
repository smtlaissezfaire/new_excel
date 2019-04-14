require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :compile_grammar do
  `bundle exec racc lib/new_excel/new_excel_grammar.y -o lib/new_excel/new_excel_grammar.rb`
end

task :default => [:compile_grammar, :spec]
