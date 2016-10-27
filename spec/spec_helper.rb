require 'puppetlabs_spec_helper/module_spec_helper'
require 'rake'
require 'rspec-puppet-facts'

include RspecPuppetFacts

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
hiera_path   = File.expand_path(File.join(__FILE__, '..', 'hiera'))

RSpec.configure do |c|
  c.module_path  = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.pattern      = FileList[c.pattern].exclude(/^spec\/fixtures/)
  c.hiera_config = File.join(hiera_path, 'hiera.yaml')
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end

Puppet::Util::Log.level = :warning
Puppet::Util::Log.newdestination(:console)
