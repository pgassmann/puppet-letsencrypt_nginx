require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'letsencrypt_nginx::location', :type => 'define' do
  let(:facts_default) do
    {
      :operatingsystem        => 'Ubuntu',
      :osfamily               => 'Debian',
      :os                     => {
        'architecture' => "amd64",
        'distro' => {
          'codename' => "xenial",
          'description' => "Ubuntu 16.04.5 LTS",
          'id' => "Ubuntu",
          'release' => {
            'full' => "16.04",
            'major' => "16.04"
          }
        },
        'family' => "Debian",
        'hardware' => "x86_64",
        'name' => "Ubuntu",
        'release' => {
          'full' => "16.04",
          'major' => "16.04"
        },
        'selinux' => {
          'enabled' => false
        }
      },
      :operatingsystemrelease => '16.04',
      :lsbdistcodename        => 'xenial',
      :lsbdistid              => 'Ubuntu',
      :lsbdistrelease         => '16.04',
      :ipaddress6             => '::1',
      :path                   => '/usr/bin',
      :puppetversion          => Puppet.version,
      :concat_basedir         => '/var/lib/puppet/concat',
      :puppet_vardir          => '/var/lib/puppet',
    }
  end
  let(:facts) do
    facts_default.merge({})
  end
  let(:title) { 'mydomain.example.com' }
  let(:pre_condition) do
    "
      Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
      class { ::letsencrypt:
        email => 'foo@example.com',
      }
      # nginx configuration
      class{'nginx':
        manage_repo => false;
      }
      nginx::resource::server{'mydomain.example.com':
        server_name => [
                  'mydomain.example.com',
                  'www.mydomain.example.com',
                  'mydomain2.example.com',
        ],
        proxy                => 'http://10.1.2.3',
        ipv6_enable          => true,
        ipv6_listen_options  => '',
        ssl                  => true,
        ssl_redirect     => true,
        ssl_key              => '/etc/letsencrypt/live/mydomain.example.com/privkey.pem',
        ssl_cert             => '/etc/letsencrypt/live/mydomain.example.com/fullchain.pem',
      }
    "
  end
  context "with default" do
    it { should compile.with_all_deps }
    it { should contain_nginx__resource__location('mydomain.example.com-letsencrypt').with(
      :server    => 'mydomain.example.com',
      :location => '/.well-known/acme-challenge',
      :www_root =>  '/var/lib/letsencrypt/webroot',
      :ssl      =>  true,
      :auth_basic => 'off',
   )}
  end
end
