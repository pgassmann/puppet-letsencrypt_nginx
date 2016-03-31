# letsencrypt webroot
define letsencrypt_wrap::exec::webroot (
  $domains = [$name],
  $webroot = $letsencrypt_wrap::webroot,
  $server  = $letsencrypt_wrap::server,
){
  include letsencrypt_wrap
  validate_array($domains)
  validate_string($server)
  validate_string($webroot)

  $params_domain = join($domains, ' -d ')

  if $letsencrypt_wrap::firstrun_standalone and $::letsencrypt_firstrun != 'SUCCESS' {
    letsencrypt_wrap::exec::standalone{ $name:
      domains => $domains,
      server  => $server,
    }
    # TODO FIXME: This fails if webroot is defined multiple times
    file{ ['/etc/facter', '/etc/facter/facts.d']: ensure => directory; }
    file{ '/etc/facter/facts.d/letsencrypt.txt':
      content => 'letsencrypt_firstrun=SUCCESS',
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Letsencrypt_wrap::Exec::Standalone[$name];
    }
  } else {
    if $letsencrypt_wrap::firstrun_webroot and $::letsencrypt_firstrun != 'SUCCESS'{
      $real_webroot = $letsencrypt_wrap::firstrun_webroot
      # TODO FIXME: This fails if webroot is defined multiple times
      file{ ['/etc/facter', '/etc/facter/facts.d']: ensure => directory; }
      file{ '/etc/facter/facts.d/letsencrypt.txt':
        content => 'letsencrypt_firstrun=SUCCESS',
        owner   => root,
        group   => root,
        mode    => '0644',
        require => Exec["letsencrypt-exec-webroot-${name}"],
      }
    } else {
    $real_webroot = $webroot
    }
    exec{ "letsencrypt-exec-webroot-${name}":
      command => "letsencrypt certonly -a webroot --webroot-path ${real_webroot} -d ${params_domain} --renew-by-default --server ${server}",
      creates => "/etc/letsencrypt/live/${domains[0]}/fullchain.pem",
      require  => File['/etc/letsencrypt/cli.ini'];
    }
  }
}
