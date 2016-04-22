# Let's Encrypt Nginx
# == Define: letsencrypt_nginx::location
#
# Configure acme-challenge location webroot for a nginx vhost
#
# === Parameters
#
#  * `vhost`: vhost to configure location for, defaults to $name
#
define letsencrypt_nginx::location(
  $vhost    = $name,
){
  include letsencrypt_nginx
  # if vhost is set as default_vhost, then the location is already added.
  unless defined(Nginx::Resource::Location["${vhost}-letsencrypt"]) {
    if defined(Nginx::Resource::Vhost[$vhost]){
      $vhost_ssl = getparam(Nginx::Resource::Vhost[$vhost], 'ssl')
    } else {
      $vhost_ssl = true
    }
    # getparam returns undef (or '' in Puppet 4) if specified false or if not defined.
    # Set it to default of vhost param ssl.
    # Note: It should be true for every vhost except the default vhost
    if ($vhost_ssl == undef or $vhost_ssl == '') {
      $real_vhost_ssl = false
    } else {
      $real_vhost_ssl = $vhost_ssl
    }
    validate_bool($real_vhost_ssl)
    nginx::resource::location{"${vhost}-letsencrypt":
      vhost    =>  $vhost,
      location =>  '/.well-known/acme-challenge',
      www_root =>  $letsencrypt_nginx::webroot,
      ssl      =>  $real_vhost_ssl,
    }
  }
}
