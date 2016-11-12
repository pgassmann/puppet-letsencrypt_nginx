# Let's Encrypt Nginx
# == Define: letsencrypt_nginx::vhost
#
# Automatically get ssl certificate for nginx vhost
#
# === Parameters
#
#  * `domains`:
#    Array of domains to get ssl certificate for.
#    If not defined, it uses the server_name array defined in the vhost.
#    Use these domains instead of reading server_name array of vhost.
#
#  * `exclude_domains`:
#    Array of servernames that should not be added as alt names for the ssl cert.
#    E.g. Elements of server_name that are defined in the vhost,
#    but are not public resolvable or not valid fqdns.
#
#  * `webroot_paths`:
#    Passed to letsencrypt::certonly, not recommended to change
#    An array of webroot paths for the domains in `domains`.
#    Required if using `plugin => 'webroot'`. If `domains` and
#    `webroot_paths` are not the same length, `webroot_paths`
#    will cycle to make up the difference.
#
#  * `additional_args`:
#    Passed to letsencrypt::certonly
#    An array of additional command line arguments to pass to the
#    `letsencrypt-auto` command.
#
#  * `manage_cron`:
#    Passed to letsencrypt::certonly, default: true
#    Boolean indicating whether or not to schedule cron job for renewal.
#    Runs daily but only renews if near expiration, e.g. within 10 days.
#
define letsencrypt_nginx::vhost(
  $vhost           = $name,
  $domains         = undef,
  $exclude_domains = [],
  $webroot_paths   = undef,
  $additional_args = undef,
  $manage_cron     = true,
){
  include letsencrypt_nginx

  if is_hash($::facts) {
    $firstrun_fact = $::facts['letsencrypt_nginx_firstrun']
  } else {
    $firstrun_fact = $::letsencrypt_nginx_firstrun
  }

  validate_array($exclude_domains)
  if $webroot_paths {
    validate_array($webroot_paths)
    $real_webroot_paths = $webroot_paths
  } else {
    $real_webroot_paths = [$letsencrypt_nginx::webroot]
    # if vhost is set as default_vhost, then the location is already added.
    ensure_resource('letsencrypt_nginx::location', $vhost )
  }

  if $domains {
    validate_array($domains)
    $real_domains = delete($domains, $exclude_domains)
  } else {
    if defined(Nginx::Resource::Vhost[$vhost]){
      $vhost_domains = getparam(Nginx::Resource::Vhost[$vhost], 'server_name')
      $real_domains  = delete($vhost_domains, $exclude_domains)
    } else {
      fail("no domains specified and Nginx::Resource::Vhost[${vhost}] is not yet defined, make sure that letsencrypt_nginx::vhost is parsed after nginx::resource::vhost")
    }
  }

  if $letsencrypt_nginx::firstrun_standalone and $firstrun_fact != 'SUCCESS' {
    letsencrypt::certonly{ "${name}_firstrun_standalone":
      plugin          => 'standalone',
      domains         => $real_domains,
      additional_args => $additional_args,
      manage_cron     => false,
      before          => Letsencrypt::Certonly[$name],
      notify          => Exec['set letsencrypt_nginx_firstrun fact'];
    }
  }
  if $letsencrypt_nginx::firstrun_webroot and $firstrun_fact != 'SUCCESS'{
    letsencrypt::certonly{ "${name}_firstrun_webroot":
      plugin          => 'webroot',
      domains         => $real_domains,
      webroot_paths   => [$letsencrypt_nginx::firstrun_webroot],
      additional_args => $additional_args,
      manage_cron     => false,
      before          => Letsencrypt::Certonly[$name],
      notify          => Exec['set letsencrypt_nginx_firstrun fact'];
    }
  }
  # Always define letsencrypt::certonly with webroot for cronjob,
  # exec will not be executed again, if certificate exists
  letsencrypt::certonly{ $name:
    plugin          => 'webroot',
    domains         => $real_domains,
    webroot_paths   => $real_webroot_paths,
    additional_args => $additional_args,
    manage_cron     => $manage_cron,
    notify          => Service['nginx'];
  }
}
