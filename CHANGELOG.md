# Change log
All notable changes to this project will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]
* Disable basic auth for acme-challenge location

## [1.1.2] - 2016-04-22
* Fix for Puppet 4.x

## [1.1.1] - 2016-04-01
* Initial release of letsencrypt_nginx using letsencrypt::certonly from danzilio-letsencrypt

## History
* Before, I wrote a standalone module which also installed and executed letsencrypt. This was dropped in favor of danzilio-letsencrypt.
