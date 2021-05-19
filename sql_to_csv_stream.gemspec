# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sql_to_csv_stream/version'

Gem::Specification.new do |spec|
  spec.name          = 'sql_to_csv_stream'
  spec.version       = SqlToCsvStream::VERSION
  spec.authors       = ['Philipp Tessenow']
  spec.email         = ['philipp@tessenow.org']

  spec.summary       = 'A shortcut to the COPY command from PostgreSQL. Give it SQL and get an Enumerator for the CSV that comes out of it.'
  spec.description   = 'A shortcut to the COPY command from PostgreSQL. Give it SQL and get an Enumerator for the CSV that comes out of it.'
  spec.homepage      = 'https://github.com/tessi/sql_to_csv_stream'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/tessi/sql_to_csv_stream'
    spec.metadata['changelog_uri'] = 'https://github.com/tessi/sql_to_csv_stream/master/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'fivemat'

  # for the rails dummy app
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'puma', '~> 5.3'
  spec.add_development_dependency 'rails', '~> 5.2.4'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-bitcrowd'
  spec.add_development_dependency 'rubocop-rails'
end
