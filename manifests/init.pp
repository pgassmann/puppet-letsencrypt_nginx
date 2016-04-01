# Let's Encrypt Nginx
# == Class: letsencrypt_nginx
#
# Let's Encrypt base configuration and hiera interface.
#
# === Parameters
#
#  * `default_vhost_name`:
#    name of nginx vhost that catches all requests that do not match any other server_name
#
#  * `webroot`:
#    This directory is configured as webroot for the webroot authentication
#    locations added to the vhost to allow renewals
#
#  * `firstrun_webroot`:
#    Use different webroot on first run.
#    Set this to the default webroot of the webserver if the service
#    starts automatically when installed.
#    E.g. For Nginx on Ubuntu: /usr/share/nginx/html
#
#  * `firstrun_standalone`:
#    Use standalone mode on first run.
#    Set this to true if the webserver does not start automatically when installed.
#    letsencrypt will use standalone mode to get the certificate
#    before the webserver is started the first time.
#
#  * `locations`, `vhosts`:
#    These Parameters can be used to create instances of these defined types through hiera
#
class letsencrypt_nginx (
  $default_vhost_name  = 'default',
  $webroot             = '/var/lib/letsencrypt/webroot',
  $firstrun_webroot    = undef, # For Debian & Nginx: /usr/share/nginx/html
  $firstrun_standalone = false,
  $locations           = {},
  $vhosts              = {},
) {
  include nginx
  require ::letsencrypt

  # define webroot directory for letsencrypt challenge
  if $webroot == '/var/lib/letsencrypt/webroot' {
    file{ ['/var/lib/letsencrypt','/var/lib/letsencrypt/webroot']:
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0644';
    }
  }

  # configure default nginx vhost if not defined yet
  if $default_vhost_name == 'default' {
    unless defined(Nginx::Resource::Vhost['default']){
      nginx::resource::vhost{ 'default':
        listen_options => default_server,
        server_name    => ['default'],
        www_root       => $webroot,
      }
    }
  }

  exec{ 'set letsencrypt_nginx_firstrun fact':
    command     => 'mkdir -p /etc/facter/facts.d/ && echo "letsencrypt_nginx_firstrun=SUCCESS" > /etc/facter/facts.d/letsencrypt_nginx.txt',
    refreshonly => true,
  }

  create_resources('letsencrypt_nginx::location',  $locations)
  create_resources('letsencrypt_nginx::vhost',     $vhosts)

  # configure location for letsencrypt challenge path for default vhost
  ensure_resource('letsencrypt_nginx::location', $default_vhost_name )
}
