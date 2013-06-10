# Class: qpid::server
#
# This module manages the installation and config of the qpid server.
class qpid::server(
  $package_ensure = present,
  $service_ensure = running,

  $qpid_port = '5672',
  $auth = 'no',
  $auth_realm = 'QPID',
  $log_to_file = 'UNSET',
  $cluster_mechanism = 'DIGEST-MD5 ANONYMOUS',
  
  $qpid_cluster = false,
  $qpid_cluster_name = 'qpid_cluster',
  $qpid_username = 'nova',
  $qpid_password = 'nova'
) {

  validate_re($auth, '^(yes$|no$)')

  include qpid::params

  package { $::qpid::params::package_name:
    ensure => $package_ensure,
  }
 
  if $qpid_cluster {
    package { $::qpid::params::cluster_package_name:
      ensure => $package_ensure,
      require => Package[$::qpid::params::package_name],
    }
  }

  if $auth == 'yes' {
    qpid_user { 'qpid_user':
      password => $qpid_password,
      file => '/var/lib/qpidd/qpidd.sasldb',
      realm => $auth_realm,
      name => $qpid_username,
      provider => 'saslpasswd2',
      require => Package[$::qpid::params::package_name],
    } ->

    file {'/var/lib/qpidd/qpidd.sasldb':
      ensure => present,
      owner => 'qpidd',
      group => 'qpidd',
      mode => 600,
      before => File[$::qpid::params::config_file]
    }
  }

  file { $::qpid::params::config_file:
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => 644,
    content => template('qpid/qpidd.conf.erb'),
    require => Package[$::qpid::params::package_name],
    notify => Service[$::qpid::params::service_name],
  }

  if $log_to_file != 'UNSET' {
    file { $log_to_file:
      ensure => present,
      owner => 'qpidd',
      group => 'qpidd',
      mode => 644,
      require => Package[$::qpid::params::package_name],
    }
  }

  if $qpid_cluster {
    service { $::qpid::params::service_name:
      enable => true,
      ensure => $service_ensure,
      hasstatus  => true,
      hasrestart => true,
      require => Exec['corosync-restart'],
      subscribe => Exec['corosync-restart'],
      require => [Package[$::qpid::params::package_name], File[$::qpid::params::config_file]],
    }
  }
  else {
    service { $::qpid::params::service_name:
      enable => true,
      ensure => $service_ensure,
      hasstatus  => true,
      hasrestart => true,
      require => [Package[$::qpid::params::package_name], File[$::qpid::params::config_file]],
    }
  }
}
