# Let's Encrypt
# == Class: letsencrypt_wrap
#
# Let's Encrypt base configuration and hiera interface.
#
# === Parameters
#
# [*email*]
#   Required, email-address for registration and key recovery
#
# [*agree_tos*]
#   Required true,  Please read the Terms of Service at
#   https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf.
#   You must agree in order to register with the ACME
#   server at https://acme-v01.api.letsencrypt.org/directory
#
# [*server*]
#   ACME Server, defaults to staging instance. For Production use
#   set it to 'https://acme-v01.api.letsencrypt.org/directory'
#
# [*webroot*]
#   This directory is configured as webroot for the webroot authentication
#   locations added to the vhost to allow renewals
#
# [*firstrun_webroot*]
#   Use different webroot on first run.
#   Set this to the default webroot of the webserver if the service
#   starts automatically when installed.
#   E.g. Nginx on Ubuntu: /usr/share/nginx/html
#
# [*firstrun_standalone*]
#   Use standalone mode on first run.
#   Set this to true if the webserver does not start automatically when installed.
#   letsencrypt will use standalone mode to get the certificate
#   before the webserver is started the first time.
#
# [*rsa_key_size*], [*work_dir*], [*logs_dir*],
#   Configruation options for letsencrypt cli.ini
#
# [*nginx_locations*], [*nginx_vhosts*], [*exec_standalone*], [*exec_webroot*]
#   These Parameters can be used to create instances of these defined types through hiera
#
# === Examples
#
#  class { 'letsencrypt_wrap':
#    email            => 'email@example.com',
#    agree_tos        => true
#    firstrun_webroot => '/usr/share/nginx/html'
#    nginx_vhosts     => {
#      'mydomain.example.com' => {}
#    }
#  }
#
# === Authors
#
# Philipp Gassmann <phiphi@phiphi.ch>
#
# === Copyright
#
# Copyright 2015 Philipp Gassmann here, unless otherwise noted.
#
class letsencrypt_wrap (
  $email,
  $agree_tos           = false,
  $server              = 'https://acme-staging.api.letsencrypt.org/directory', # 'https://acme-v01.api.letsencrypt.org/directory', #
  $webroot             = '/var/lib/letsencrypt/webroot',
  $firstrun_webroot    = undef, # For Debian & Nginx: /usr/share/nginx/html
  $firstrun_standalone = false,
  $rsa_key_size        = '2048',
  $work_dir            = '/var/lib/letsencrypt',
  $logs_dir            = '/var/log/letsencrypt',
  $nginx_locations     = {},
  $nginx_vhosts        = {},
  $exec_webroot        = {},
  $exec_standalone     = {},
) {
  include letsencrypt_wrap::install

  unless $agree_tos { fail('letsencrypt_wrap: Please read the Terms of Service at https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf. You must agree in order to register with the ACME server at https://acme-v01.api.letsencrypt.org/directory') }

  file{ [
      '/etc/letsencrypt',
      '/var/lib/letsencrypt',
      '/var/lib/letsencrypt/webroot',
    ]:
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0644';
  }

  file{'/etc/letsencrypt/cli.ini':
    content => template('letsencrypt_wrap/cli.ini.erb'),
    owner   => root,
    group   => root,
    mode    => '0640',
    require => Class['letsencrypt_wrap::install'];
  }
  create_resources('letsencrypt_wrap::nginx::location',  $nginx_locations)
  create_resources('letsencrypt_wrap::nginx::vhost',     $nginx_vhosts)
  create_resources('letsencrypt_wrap::exec::webroot',    $exec_webroot)
  create_resources('letsencrypt_wrap::exec::standalone', $exec_standalone)
}
