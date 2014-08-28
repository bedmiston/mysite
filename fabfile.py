from __future__ import with_statement
from fabric.api import env, local, settings, abort, require, run, cd, sudo
from fabric.contrib.console import confirm

def vagrant():
    # change from the default user to 'vagrant'
    env.user = 'vagrant'
    # connect to the port-forwarded ssh
    env.hosts = ['127.0.0.1:2222']

    # use vagrant ssh key
    result = local('vagrant ssh-config | grep IdentityFile', capture=True)
    env.key_filename = result.split()[1]

def test():
    with settings(warn_only=True):
        result = local('./manage.py test', capture=True)
    if result.failed and not confirm("Tests failed. Continue anyway?"):
        abort("Aborting at user request.")


def commit():
    local("git add -p && git commit")


def push():
    local("git push")


def prepare_deploy():
    test()
    commit()
    push()


def deploy():
    prepare_deploy()
    code_dir = '/vagrant/'
    with cd(code_dir):
        run("git pull")


# def cmd(cmd=""):
#     '''Run a command in the site directory.  Usable from other commands or the CLI.'''
#     require('site_path')

#     if not cmd:
#         sys.stdout.write(_cyan("Command to run: "))
#         cmd = raw_input().strip()

#     if cmd:
#         with cd(env.site_path):
#             run(cmd)


# def sdo(cmd=""):
#     '''Sudo a command in the site directory.  Usable from other commands or the CLI.'''
#     require('site_path')

#     if not cmd:
#         sys.stdout.write(_cyan("Command to run: sudo "))
#         cmd = raw_input().strip()

#     if cmd:
#         with cd(env.site_path):
#             sudo(cmd)


# def vcmd(cmd=""):
#     '''Run a virtualenv-based command in the site directory.  Usable from other commands or the CLI.'''
#     require('site_path')
#     require('venv_path')

#     if not cmd:
#         sys.stdout.write(_cyan("Command to run: %s/bin/" % env.venv_path.rstrip('/')))
#         cmd = raw_input().strip()

#     if cmd:
#         with cd(env.site_path):
#             run(env.venv_path.rstrip('/') + '/bin/' + cmd)


# def vsdo(cmd=""):
#     '''Sudo a virtualenv-based command in the site directory.  Usable from other commands or the CLI.'''
#     require('site_path')
#     require('venv_path')

#     if not cmd:
#         sys.stdout.write(_cyan("Command to run: sudo %s/bin/" % env.venv_path.rstrip('/')))
#         cmd = raw_input().strip()

#     if cmd:
#         with cd(env.site_path):
#             sudo(env.venv_path.rstrip('/') + '/bin/' + cmd)


# def syncdb():
#     '''Run syncdb.'''
#     require('site_path')
#     require('venv_path')

#     with cd(env.site_path):
#         run(_python('manage.py syncdb --noinput'))


# def collectstatic():
#     '''Collect static media.'''
#     require('site_path')
#     require('venv_path')

#     with cd(env.site_path):
#         sudo(_python('manage.py collectstatic --noinput'))


# def rebuild_index():
#     '''Rebuild the search index.'''
#     require('site_path')
#     require('venv_path')
#     require('process_owner')

#     with cd(env.site_path):
#         sudo(_python('manage.py rebuild_index'))
#         sudo('chown -R %s .xapian' % env.process_owner)


# def update_index():
#     '''Update the search index.'''
#     require('site_path')
#     require('venv_path')
#     require('process_owner')

#     with cd(env.site_path):
#         sudo(_python('manage.py update_index'))
#         sudo('chown -R %s .xapian' % env.process_owner)
