class init {

    group { "puppet":
        ensure => "present",
    }

    # Let's update the system
    exec { "update-apt":
        command => "sudo apt-get update",
    }

    exec { "upgrade-apt":
        command => 'sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade',
        require => Exec["update-apt"],
        timeout => 1800,
    }

    # Let's install the dependecies
    package {
        ["libjs-jquery", "libjs-jquery-ui", "iso-codes", "gcc", "gettext",
            "bzr", "libpq-dev", "nginx", "supervisor", "sqlite3", "git",
            "build-essential"]:
        ensure => installed,
        require => Exec['update-apt'] # The system update needs to run first
    }

    # Let's install the project dependecies from pip
    exec { "pip-install-requirements":
        command => "sudo pip install -r /vagrant/requirements.txt",
        tries => 2,
        timeout => 600, # Too long, but this can take awhile
        require => Package['python-pip', 'python-dev'], # The package dependecies needs to run first
        logoutput => on_failure,
    }

    service { "nginx":
        ensure => running,
        hasrestart => true,
        require => Package['nginx'],
    }

    file { "/etc/nginx/nginx.conf":
        owner  => root,
        group  => root,
        mode   => 644,
        source => "puppet:////vagrant/puppet/files/nginx.conf",
        require => Package['nginx'],
        notify => Service['nginx']
    }

    file { "/etc/nginx/sites-available/vagrantsite":
        owner  => root,
        group  => root,
        mode   => 644,
        source => "puppet:////vagrant/puppet/files/vhost.conf",
        require => Package['nginx'],
        notify => Service['nginx']
    }

    file { "/etc/nginx/sites-enabled/vagrantsite":
        ensure => symlink,
        target => "/etc/nginx/sites-available/vagrantsite",
        require => Package['nginx'],
        notify => Service['nginx']
    }

    file { "/etc/nginx/sites-enabled/default":
        ensure => absent,
        require => Package['nginx'],
        notify => Service['nginx']
    }

    service { "supervisor":
        ensure => running,
        hasrestart => true,
        require => Package['supervisor'],
    }

    file { "/etc/supervisor/conf.d/gunicorn.conf":
        owner  => root,
        group  => root,
        mode   => 755,
        source => "puppet:////vagrant/puppet/files/gunicorn-supervisord.conf",
        require => Package['supervisor'],
    } ->
    exec { "reread_gunicorn":
        command => "sudo supervisorctl reread"
    } ->
    exec { "start_gunicorn":
        command => "sudo supervisorctl update"
    }

    group { "webapps":
        ensure => present,
        system => true,
    }

    user { "mysite":
        ensure => present,
        system => true,
        home => "/webapps/mysite",
        shell => "/bin/bash",
        groups => webapps,
        require => Group["webapps"],
    }

    file { "/webapps":
        ensure => directory,
        owner => mysite,
        group => webapps,
        mode => 644,
        require => User["mysite"],
    }

    vcsrepo { "/webapps/mysite":
        ensure   => present,
        provider => git,
        source   => "https://github.com/bedmiston/mysite.git",
        user => 'mysite',
        require => File["/webapps/mysite"],
    }

    file { "/tmp/Puppetfile":
        mode   => 755,
        source => "puppet:////vagrant/puppet/Puppetfile",
    }

    class { 'python':
        version    => 'system',
        pip        => true,
        dev        => true,
        virtualenv => true,
        gunicorn   => false,
    }

    python::virtualenv { '/webapps/mysite':
        ensure       => present,
        version      => 'system',
        requirements => '/webapps/mysite/requirements.txt',
        systempkgs   => true,
        venv_dir     => '/webapps/mysite',
        owner        => 'mysite',
        group        => 'webapps',
        cwd          => '/webapps/mysite',
        timeout      => 0,
    }

    class { 'postgresql::server': }

    postgresql::server::role {'mysite':
        password_hash => postgresql_password('mysite', '1234abcd'),
        createdb => 'true',
    }

    postgresql::server::role {'vagrant':
        createdb => 'true',
    }

    postgresql::server::database { 'mysite': }

    postgresql::server::database_grant { 'mysite':
        privilege => 'ALL',
        db => 'mysite',
        role => 'mysite',
    }
}
