# Let's Encrypt Nginx
# == Define: letsencrypt_nginx::location
#
# Configure acme-challenge location webroot for a nginx server
#
# === Parameters
#
#  * `server`: server to configure location for, defaults to $name
#
define letsencrypt_nginx::location(
  $server = $name,
){
  include letsencrypt_nginx
  # if server is set as default_server, then the location is already added.
  unless defined(Nginx::Resource::Location["${server}-letsencrypt"]) {
    if defined(Nginx::Resource::Server[$server]){
      $server_ssl = getparam(Nginx::Resource::Server[$server], 'ssl')
    } else {
      $server_ssl = true
    }
    # getparam returns undef (or '' in Puppet 4) if specified false or if not defined.
    # Set it to default of server param ssl.
    # Note: It should be true for every server except the default server
    if ($server_ssl == undef or $server_ssl == '') {
      $real_server_ssl = false
    } else {
      $real_server_ssl = $server_ssl
    }
    validate_legacy(Boolean, 'validate_bool', $real_server_ssl)
    nginx::resource::location{"${server}-letsencrypt":
      server     => $server,
      location   => '/.well-known/acme-challenge',
      www_root   => $letsencrypt_nginx::webroot,
      ssl        => $real_server_ssl,
      ssl_only   => $real_server_ssl,
      auth_basic => 'off',
    }
  }
}
