class filterserver {
  class {'nginx':
    worker_processes => 2,
    worker_connections => 4000,
    ssl_session_cache => off,
  }

  class {'statsclient':
    log_path => '/var/log/nginx/access_log_easylist_downloads.1.gz',
  }

  user {'subscriptionstat':
    ensure => absent,
  }

  user {'rsync':
    ensure => present,
    comment => 'Filter list mirror user',
    home => '/home/rsync',
    managehome => true
  }

  File {
    owner => root,
    group => root,
    mode => 0644,
  }

  file {'/var/www':
    ensure => directory
  }

  file {'/var/www/easylist':
    ensure => directory,
    require => [
                 File['/var/www'],
                 User['rsync']
               ],
    owner => rsync
  }

  file {'/etc/nginx/sites-available/inc.easylist-downloads':
    ensure => absent,
  }

  file {'/etc/nginx/sites-available/inc.easylist-downloads-txt':
    ensure => absent
  }

  file {'/etc/nginx/sites-available/inc.easylist-downloads-tpl':
    ensure => absent
  }

  file {'/etc/nginx/sites-available/easylist-downloads.adblockplus.org_sslcert.key':
    ensure => file,
    notify => Service['nginx'],
    before => Nginx::Hostconfig['easylist-downloads.adblockplus.org'],
    source => 'puppet:///modules/private/easylist-downloads.adblockplus.org_sslcert.key'
  }

  file {'/etc/nginx/sites-available/easylist-downloads.adblockplus.org_sslcert.pem':
    ensure => file,
    notify => Service['nginx'],
    before => Nginx::Hostconfig['easylist-downloads.adblockplus.org'],
    mode => 0400,
    source => 'puppet:///modules/private/easylist-downloads.adblockplus.org_sslcert.pem'
  }

  nginx::hostconfig{'easylist-downloads.adblockplus.org':
    source => 'puppet:///modules/filterserver/easylist-downloads.adblockplus.org',
    enabled => true
  }

  file {'/etc/logrotate.d/nginx_easylist-downloads.adblockplus.org':
    ensure => file,
    require => Nginx::Hostconfig['easylist-downloads.adblockplus.org'],
    source => 'puppet:///modules/filterserver/logrotate'
  }

  file {'/home/rsync/.ssh':
    ensure => directory,
    require => User['rsync'],
    owner => rsync,
    mode => 0600;
  }

  file {'/home/rsync/.ssh/known_hosts':
    ensure => file,
    require => [
                 File['/home/rsync/.ssh'],
                 User['rsync']
               ],
    owner => rsync,
    mode => 0444,
    source => 'puppet:///modules/filterserver/known_hosts'
  }

  file {'/home/rsync/.ssh/id_rsa':
    ensure => file,
    require => [
                 File['/home/rsync/.ssh'],
                 User['rsync']
               ],
    owner => rsync,
    mode => 0400,
    source => 'puppet:///modules/private/rsync@easylist-downloads.adblockplus.org'
  }

  file {'/home/rsync/.ssh/id_rsa.pub':
    ensure => file,
    require => [
                 File['/home/rsync/.ssh'],
                 User['rsync']
               ],
    owner => rsync,
    mode => 0400,
    source => 'puppet:///modules/private/rsync@easylist-downloads.adblockplus.org.pub'
  }

  cron {'mirror':
    ensure => present,
    require => [
                 File['/home/rsync/.ssh/known_hosts'],
                 File['/home/rsync/.ssh/id_rsa'],
                 User['rsync']
               ],
    command => 'rsync -e ssh -ltprz --delete rsync@ssh.adblockplus.org:. /var/www/easylist/',
    environment => ['MAILTO=admins@adblockplus.org,root'],
    user => rsync,
    hour => '*',
    minute => '2-52/10'
  }
}
