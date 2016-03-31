# nginx base config
class letsencrypt_wrap::nginx(
  $default_vhost = 'default'
) {
  include letsencrypt_wrap

  unless defined(Nginx::Resource::Vhost[$default_vhost]){
    nginx::resource::vhost{ 'default':
        listen_options => default_server,
        server_name    => ['default'],
        www_root       => $letsencrypt_wrap::webroot,
    }

  }
#  unless defined(Letsencrypt::Nginx::Location[$default_vhost]){
#    letsencrypt_wrap::nginx::location{$default_vhost:}
#  }
  ensure_resource('letsencrypt_wrap::nginx::location', $default_vhost )
}
