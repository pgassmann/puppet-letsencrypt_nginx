# letsencrypt standalone
define letsencrypt_wrap::exec::standalone (
  $domains = [$name],
  $server  = $letsencrypt_wrap::server,
){
  include letsencrypt_wrap
  validate_array($domains)
  validate_string($server)

  $params_domain = join($domains, ' -d ')
  exec{ "letsencrypt-exec-standalone-${name}":
    command  => "letsencrypt certonly -a standalone -d ${params_domain} --renew-by-default --server ${server}",
    creates  => "/etc/letsencrypt/live/${domains[0]}/fullchain.pem",
    require  => File['/etc/letsencrypt/cli.ini'];
  }
}
