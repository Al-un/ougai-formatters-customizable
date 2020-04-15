lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ougai/formatters/customizable/version'

Gem::Specification.new do |spec|
  spec.name          = 'ougai-formatters-customizable'
  spec.version       = Ougai::Formatters::CUSTOMIZABLE_VERSION
  spec.authors       = ['Al-un']
  spec.email         = ['alun.sng@gmail.com']

  spec.summary       = 'Customizable formatter for Ougai library'
  spec.description   = <<-DESC_BLOCK
    This library aims at providing a fully flexible formatter compatible with the
    Ougai library. Customization is about colorization and log formatting.
  DESC_BLOCK
  spec.homepage      = 'https://github.com/Al-un/ougai-formatters-customizable'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems >=2.0 is required to protect against public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir['lib/**/*.rb'] + ['README.md', 'LICENSE.txt']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # runtimes dependencies
  spec.add_runtime_dependency 'ougai', '~>1.7', '>= 1.7.0'

  # development specific dependencies. Used when +gem install --dev your_gem+
  spec.add_development_dependency 'amazing_print', '~> 1.0'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'simplecov-console', '~> 0.4.2'
end
