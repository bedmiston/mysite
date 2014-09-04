from __future__ import with_statement
from fabric.api import env, local, settings, abort, require, run, cd, sudo
from fabric.contrib.console import confirm


def vagrant():
    # change from the default user to 'vagrant'
    env.user = 'vagrant'
    # connect to the port-forwarded ssh
    env.hosts = ['127.0.0.1:2222']
    # Set the site path
    env.site_path = '/webapps/mysite/'

    # use vagrant ssh key
    result = local('vagrant ssh-config | grep IdentityFile', capture=True)
    env.key_filename = result.split()[1]


def test():
    with settings(warn_only=True):
        result = local('python manage.py test', capture=False)
    if result.failed and not confirm("Tests failed. Continue anyway?"):
        abort("Aborting at user request.")


def commit():
    local("git add -p && git commit")


def push():
    local("git push")


def prepare_deploy():
    '''Prepare to deploy the site'''
    test()
    commit()
    push()


def deploy():
    '''Deploy the site.'''
    prepare_deploy()
    with cd(env.site_path):
        run("git pull")
    syncdb()
    collectstatic()


def uname():
    '''Run uname on the server.'''
    run('uname -a')


def syncdb():
    '''Sync the database.'''
    with cd(env.site_path):
        run('python manage.py syncdb --noinput')


def collectstatic():
    '''Collect static media.'''
    with cd(env.site_path):
        sudo('python manage.py collectstatic --noinput')
