require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'letsencrypt_nginx::server', :type => 'define' do
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
        ssl_redirect     => true,
        ssl                  => true,
        ssl_key              => '/etc/letsencrypt/live/mydomain.example.com/privkey.pem',
        ssl_cert             => '/etc/letsencrypt/live/mydomain.example.com/fullchain.pem',
      }
    "
  end
  context "with default" do
    it { should compile.with_all_deps }
    it { should contain_letsencrypt_nginx__server('mydomain.example.com')}
    it { should contain_letsencrypt_nginx__location('mydomain.example.com')}
    it { should contain_letsencrypt__certonly('mydomain.example.com').with(
      :domains => [
                  'mydomain.example.com',
                  'www.mydomain.example.com',
                  'mydomain2.example.com',
        ],
      :notify  => 'Service[nginx]',
    )}
  end
  context "with no server_name param" do
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
        proxy                => 'http://10.1.2.3',
        ipv6_enable          => true,
        ipv6_listen_options  => '',
        ssl_redirect     => true,
        ssl                  => true,
        ssl_key              => '/etc/letsencrypt/live/mydomain.example.com/privkey.pem',
        ssl_cert             => '/etc/letsencrypt/live/mydomain.example.com/fullchain.pem',
      }
    "
  end
    it { should compile.with_all_deps }
    it { should contain_letsencrypt_nginx__server('mydomain.example.com')}
    it { should contain_letsencrypt_nginx__location('mydomain.example.com')}
    it { should contain_letsencrypt__certonly('mydomain.example.com').with(
      :domains => ['mydomain.example.com'],
      :notify  => 'Service[nginx]',
    )}
  end

  context "with firstrun_standalone mode" do
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
        class{ 'letsencrypt_nginx':
          firstrun_standalone => true,
        }
      "
    end
    let(:title) { 'foo.com' }
    let(:params) do
      { :domains => [ 'd1.foo.com', 'd2.bar.com'],
      }
    end
    it { should compile.with_all_deps }
    it { should contain_letsencrypt_nginx__location('foo.com')}
    it { should contain_nginx__resource__location('foo.com-letsencrypt')}
    it { should contain_letsencrypt__certonly('foo.com_firstrun_standalone').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :plugin  => 'standalone',
      :manage_cron    => false,
      :notify  => 'Exec[set letsencrypt_nginx_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :manage_cron    => true,
      :plugin  => 'webroot',
      :cron_success_command => '/bin/systemctl reload nginx.service',
    )}
  end
  context "with firstrun_standalone mode success" do
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
        class{ 'letsencrypt_nginx':
          firstrun_standalone => true,
        }
      "
    end
    let(:title) { 'foo.com' }
    let(:params) do
      { :domains => [ 'd1.foo.com', 'd2.bar.com'],
      }
    end
    let(:facts) do
      facts_default.merge({
        :letsencrypt_nginx_firstrun      => 'SUCCESS'
      })
    end
    it { should compile.with_all_deps }
    it { should_not contain_letsencrypt__certonly('foo.com_firstrun_standalone').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :plugin  => 'standalone',
      :manage_cron    => false,
      :notify  => 'Exec[set letsencrypt_nginx_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :plugin  => 'webroot',
      :cron_success_command => '/bin/systemctl reload nginx.service',
    )}
  end
  context "with firstrun_webroot " do
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
        class{ 'letsencrypt_nginx':
          firstrun_webroot => '/usr/share/nginx/html',
        }
      "
    end
    let(:title) { 'foo.com' }
    let(:params) do
      { :domains => [ 'd1.foo.com', 'd2.bar.com'],
      }
    end
    it { should compile.with_all_deps }
    it { should contain_letsencrypt__certonly('foo.com_firstrun_webroot').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :plugin  => 'webroot',
      :manage_cron    => false,
      :webroot_paths  => ['/usr/share/nginx/html'],
      :notify  => 'Exec[set letsencrypt_nginx_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :manage_cron    => true,
      :plugin         => 'webroot',
      :cron_success_command => '/bin/systemctl reload nginx.service',
    )}
  end
  context "with firstrun_webroot success" do
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
        class{ 'letsencrypt_nginx':
          firstrun_webroot => '/usr/share/nginx/html',
        }
      "
    end
    let(:facts) do
      facts_default.merge({
        :letsencrypt_nginx_firstrun      => 'SUCCESS'
      })
    end
    let(:title) { 'foo.com' }
    let(:params) do
      { :domains => [ 'd1.foo.com', 'd2.bar.com'],
      }
    end
    it { should compile.with_all_deps }
    it { should_not contain_letsencrypt__certonly('foo.com_firstrun_webroot').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :plugin  => 'webroot',
      :manage_cron    => false,
      :webroot_paths  => ['/usr/share/nginx/html'],
      :notify  => 'Exec[set letsencrypt_nginx_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :manage_cron    => true,
      :plugin         => 'webroot',
      :cron_success_command => '/bin/systemctl reload nginx.service',
    )}
  end

end
