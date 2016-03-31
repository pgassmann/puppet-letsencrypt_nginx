require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'letsencrypt_nginx::vhost', :type => 'define' do
  let(:facts) do
    {
      :concat_basedir            => '/var/lib/puppet/concat',
    }
  end
  let(:title) { 'mydomain.example.com' }
  let(:pre_condition) do
    "
      Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
      class { ::letsencrypt:
        email => 'foo@example.com',
      }
      include nginx
      nginx::resource::vhost{'mydomain.example.com':
        server_name => [
                  'mydomain.example.com',
                  'www.mydomain.example.com',
                  'mydomain2.example.com',
        ],
        proxy                => 'http://10.1.2.3',
        ipv6_enable          => true,
        ipv6_listen_options  => '',
        rewrite_to_https     => true,
        ssl                  => true,
        ssl_key              => '/etc/letsencrypt/live/mydomain.example.com/privkey.pem',
        ssl_cert             => '/etc/letsencrypt/live/mydomain.example.com/fullchain.pem',
      }
    "
  end
  context "with default" do
    it { should compile.with_all_deps }
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
      include nginx
      nginx::resource::vhost{'mydomain.example.com':
        proxy                => 'http://10.1.2.3',
        ipv6_enable          => true,
        ipv6_listen_options  => '',
        rewrite_to_https     => true,
        ssl                  => true,
        ssl_key              => '/etc/letsencrypt/live/mydomain.example.com/privkey.pem',
        ssl_cert             => '/etc/letsencrypt/live/mydomain.example.com/fullchain.pem',
      }
    "
  end
    it { should compile.with_all_deps }
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
    it { should contain_letsencrypt__certonly('foo.com_firstrun_standalone').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :plugin  => 'standalone',
      :manage_cron    => false,
      :notify  => 'Exec[set letsencrypt_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :manage_cron    => true,
      :plugin  => 'webroot',
    )}
  end
  context "with firstrun_standalone mode success" do
    let(:pre_condition) do
      "
        Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
        class { ::letsencrypt:
          email => 'foo@example.com',
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
      {
        :concat_basedir            => '/var/lib/puppet/concat',
        :letsencrypt_firstrun      => 'SUCCESS'
      }
    end
    it { should compile.with_all_deps }
    it { should_not contain_letsencrypt__certonly('foo.com_firstrun_standalone').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :plugin  => 'standalone',
      :manage_cron    => false,
      :notify  => 'Exec[set letsencrypt_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :plugin  => 'webroot',
    )}
  end
  context "with firstrun_webroot " do
    let(:pre_condition) do
      "
        Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
        class { ::letsencrypt:
          email => 'foo@example.com',
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
      :notify  => 'Exec[set letsencrypt_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :manage_cron    => true,
      :plugin         => 'webroot',
    )}
  end
  context "with firstrun_webroot success" do
    let(:pre_condition) do
      "
        Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }
        class { ::letsencrypt:
          email => 'foo@example.com',
        }
        class{ 'letsencrypt_nginx':
          firstrun_webroot => '/usr/share/nginx/html',
        }
      "
    end
    let(:facts) do
      {
        :concat_basedir            => '/var/lib/puppet/concat',
        :letsencrypt_firstrun      => 'SUCCESS'
      }
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
      :notify  => 'Exec[set letsencrypt_firstrun fact]',
    )}
    it { should contain_letsencrypt__certonly('foo.com').with(
      :domains => [ 'd1.foo.com', 'd2.bar.com'],
      :notify  => 'Service[nginx]',
      :manage_cron    => true,
      :plugin         => 'webroot',
    )}
  end

end
