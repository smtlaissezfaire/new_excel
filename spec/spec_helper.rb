require "bundler/setup"
require "new_excel"

require 'byebug'

RSpec.configure do |config|
  # # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"
  #
  # # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!
  #
  # config.expect_with :rspec do |c|
  #   debugger
  #   c.syntax = :should
  # end

  config.expect_with :rspec do |expectations|
    expectations.syntax = :should
  end
  
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

  config.include RSpec
end
