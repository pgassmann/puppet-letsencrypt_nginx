require 'spec_helper'
describe 'letsencrypt_nginx' do
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
  context 'with defaults for all parameters' do
    # fail email missing
  end
  context 'with default params and letsencrypt defaults' do
    let(:pre_condition) do
      "
        # Exec resource  default
        Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
        # nginx configuration
        class{'nginx':
          manage_repo => false;
        }
        # letsencrypt minimal params
        class { ::letsencrypt:
          email => 'foo@example.com',
        }
      "
    end
    it { is_expected.to contain_class('letsencrypt')}
    it { is_expected.to contain_class('letsencrypt_nginx')}
    it { is_expected.to contain_file('/var/lib/letsencrypt')}
    it { is_expected.to contain_file('/var/lib/letsencrypt/webroot')}
    it { is_expected.to contain_exec('set letsencrypt_nginx_firstrun fact').with_refreshonly(true)}
    it { should contain_letsencrypt_nginx__location('default')}
    it { should contain_nginx__resource__location('default-letsencrypt')}
    it { should compile.with_all_deps }
  end
  context 'with resources' do
    let(:pre_condition) do
      "
        # Exec resource  default
        Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
        # letsencrypt minimal params
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
    let(:params) do
      {
        :firstrun_standalone => false,
        :servers => {
          'mydomain.example.com' => {},
        },
        :locations => {
          'default' => {},
          'foo.net' => {},
        },
      }
    end
    it { should compile.with_all_deps }
    it { should contain_letsencrypt_nginx__server('mydomain.example.com')}
    it { should contain_letsencrypt_nginx__location('mydomain.example.com')}
    it { should contain_nginx__resource__server('default').with(
      :listen_options  => 'default_server',
      :www_root        =>  '/var/lib/letsencrypt/webroot',
      :server_name     => ['default'],
    )}
    it { should contain_nginx__resource__location('default-letsencrypt')}
    it { should contain_letsencrypt_nginx__location('default')}
    it { should contain_nginx__resource__location('foo.net-letsencrypt')}
    it { should contain_letsencrypt_nginx__location('foo.net')}
  end
end
