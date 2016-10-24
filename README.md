# letsencrypt_nginx

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with letsencrypt_nginx](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

The goal of [Let's Encrypt](https://letsencrypt.org) is to automate ssl certificates.

This module is a helper to manage letsencrypt for puppet managed nginx vhosts.

Works with danzilio/letsencrypt and jfryman/nginx

## Module Description

The goal of this module is to enable ssl on puppet managed nginx vhosts as
simple as possible. The module reuses the domains configured in the vhost server_name

For the authorization, the webroot challenge is used and a custom location is
automatically added to the ngninx vhost so that the challenge path is using
the letsencrypt webroot.
This allows to solve the challenge even if the vhost is just a proxy to another server.

## Setup

### What letsencrypt_nginx does

* configure locations for the letsencrypt challenge path for defined vhosts and default vhost
* Define default vhost for nginx that catches all requests that do not match a server_name
* Uses letsencrypt::certonly to get certificate (requires danzilio-letsencrypt)
* Tell letsencrypt::certonly to manage cron for renewals

### What letsencrypt_nginx does not

* Manage nginx vhost ssl configuration. Configure the vhost ssl and certificate as seen  in the examples below.

### Setup Requirements

Requests to Port 80 (and 433) of the IPv4 address of the domains to encrypt need to reach your server.

This module uses the danzilio/letsencrypt module, see it's documentation for the letsencrypt options

### Usage

See the following example for encrypting a nginx vhost.
This will successfully configure nginx, the vhost and the ssl certificat in one run, if added to a blank Server.

Important: You should declare letsencrypt_nginx resources after the nginx resources.
The fetching of the configured domains is parse order dependent.


#### Let's encrypt nginx vhost

    class{'nginx':
      vhosts => {
        'letsencrypt-test1.example.com' => {
              server_name      => [
                'letsencrypt-test1.example.com',
                'letsencrypt-test2.example.com',
              ],
              proxy            => 'http://10.1.2.3',
              ssl              => true,
              rewrite_to_https => true,
              ssl_key          => '/etc/letsencrypt/live/letsencrypt-test1.example.com/privkey.pem',
              ssl_cert         => '/etc/letsencrypt/live/letsencrypt-test1.example.com/fullchain.pem',

        },
      },
    }
    class { ::letsencrypt:
      email => 'foo@example.com',
    }
    class { 'letsencrypt_nginx':
      firstrun_webroot => '/usr/share/nginx/html',
      vhosts           => {
        'letsencrypt-test1.example.com' => {},
      },
    }

To add ssl configuration to an existing installation, you need first to configure the locations
for your default vhost and your existing vhost.

    class { 'letsencrypt_nginx':
      locations => {
        'default' => {}
        'letsencrypt-test1.example.com' => {}
      }
    }

If this is applied successfully, you can then add the ssl configuration to your nginx vhost as above and declare your letsencrypt_nginx::vhost

#### Hiera example

    classes:
      - nginx
      - letsencrypt
      - letsencrypt_nginx

    nginx::vhosts:
      'letsencrypt-test1.example.com':
          server_name:
                                - 'letsencrypt-test1.example.com'
                                - 'letsencrypt-test2.example.com'
          proxy:                'http://10.1.2.3'
          ssl:                  true
          rewrite_to_https:     true
          ssl_key:              '/etc/letsencrypt/live/letsencrypt-test1.example.com/privkey.pem'
          ssl_cert:             '/etc/letsencrypt/live/letsencrypt-test1.example.com/fullchain.pem'

    letsencrypt::email: 'foo@example.com'
    # use staging server for testing
    letsencrypt::config:
      server: 'https://acme-staging.api.letsencrypt.org/directory'

    letsencrypt_nginx::firstrun_webroot: '/usr/share/nginx/html'
    letsencrypt_nginx::vhosts:
      'letsencrypt-test1.example.com': {}


## Reference


### Class: letsencrypt_nginx

Let's Encrypt base configuration and hiera interface.

#### Parameters

* `default_vhost_name`:
  name of nginx vhost that catches all requests that do not match any other server_name

* `webroot`:
  This directory is configured as webroot for the webroot authentication
  locations added to the vhost to allow renewals

* `firstrun_webroot`:
  Use different webroot on first run.
  Set this to the default webroot of the webserver if the service
  starts automatically when installed.
  E.g. For Nginx on Ubuntu: /usr/share/nginx/html

* `firstrun_standalone`:
  Use standalone mode on first run.
  Set this to true if the webserver does not start automatically when installed.
  letsencrypt will use standalone mode to get the certificate
  before the webserver is started the first time.

* `locations`, `vhosts`:
  These Parameters can be used to create instances of these defined types through hiera


### Define: letsencrypt_nginx::vhost

Automatically get ssl certificate for nginx vhost

#### Parameters

* `domains`:
  Array of domains to get ssl certificate for.
  If not defined, it uses the server_name array defined in the vhost.
  Use these domains instead of reading server_name array of vhost.

* `exclude_domains`:
  Array of servernames that should not be added as alt names for the ssl cert.
  E.g. Elements of server_name that are defined in the vhost,
  but are not public resolvable or not valid fqdns.

* `webroot_paths`:
  Passed to letsencrypt::certonly, not recommended to change
  An array of webroot paths for the domains in `domains`.
  Required if using `plugin => 'webroot'`. If `domains` and
  `webroot_paths` are not the same length, `webroot_paths`
  will cycle to make up the difference.

* `additional_args`:
  Passed to letsencrypt::certonly
  An array of additional command line arguments to pass to the
  `letsencrypt-auto` command.

* `manage_cron`:
  Passed to letsencrypt::certonly, default: true
  Boolean indicating whether or not to schedule cron job for renewal.
  Runs daily but only renews if near expiration, e.g. within 10 days.


### Define: letsencrypt_nginx::location

Configure acme-challenge location webroot for a nginx vhost

#### Parameters

* `vhost`: vhost to configure location for, defaults to $name



## Development

Run `bundle exec rake` to execute the spec tests. There are already some basic tests for each class and define, but not all options are covered.

## Release Notes

See [CHANGELOG.md](CHANGELOG.md)

## Contributors

* Philipp Gassmann <phiphi@phiphi.ch>

## License

Apache 2.0

## TODO & Ideas

* More Testing
* Automatically configure SSL certificate and key on the vhost
* Add Domains to existing Certificates
* Support for RedHat, CentOS etc.
