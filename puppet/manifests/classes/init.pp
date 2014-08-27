class init {

    group { "puppet":
        ensure => "present",
    }

    # Let's update the system
    exec { "update-apt":
        command => "sudo apt-get update",
    }

    # Let's install the dependecies
    package {
        ["python", "python-dev", "libjs-jquery", "libjs-jquery-ui",
            "iso-codes", "gettext", "python-pip", "bzr", "libpq-dev", "postgresql",
            "postgresql-contrib", "nginx", "supervisor", "sqlite3"]:
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
}