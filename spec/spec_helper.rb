require 'simplecov'
require 'simplecov-console'
SimpleCov.formatter = SimpleCov::Formatter::Console
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'ougai'
require 'ougai/formatters/customizable'
require 'ougai/formatters/customizable/version'
require 'amazing_print'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
