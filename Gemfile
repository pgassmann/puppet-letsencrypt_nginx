source ENV['GEM_SOURCE'] || 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : ['~> 4']
gem 'metadata-json-lint'
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper', '>= 1.0.0'
gem 'puppet-lint', '>= 1.0.0'
gem 'facter', '>= 1.7.0'
gem 'rspec-puppet'
gem "rspec-puppet-facts"
gem 'puppet-blacksmith'
gem 'librarian-puppet'
gem 'highline'
gem 'rake'
gem 'parallel_tests'

if RUBY_VERSION < '2.0'
  # json 2.x requires ruby 2.0. Lock to 1.8
  gem 'json', '~> 1.8'
  gem 'json_pure', '~> 1.0'
else
  gem 'json'
end
