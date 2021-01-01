nginx-uwsgi Ansible Playbook
============================

![](https://github.com/Kwpolska/ansible-nginx-uwsgi/workflows/CI%20in%20Docker%20for%20ansible-nginx-uwsgi%20%28pyweb%29/badge.svg)

Automation for nginx and uWSGI Emperor setup. Based on my [pyweb tutorial][] and [Ansible][].

Version: 2.3 — [changelog][]

[pyweb tutorial]: https://chriswarrick.com/blog/2016/02/10/deploying-python-web-apps-with-nginx-and-uwsgi-emperor/
[Ansible]: https://www.ansible.com/
[changelog]: https://github.com/Kwpolska/ansible-nginx-uwsgi/releases

Supported OSes
--------------

The support list matches the tutorial:

* Ubuntu 16.04 LTS, 18.04 LTS, 20.04 LTS or newer
* Debian 9 (stretch) or newer
* Fedora 29 or newer (with SELinux enabled and disabled)
* CentOS 7 (with SELinux enabled and disabled)
* Arch Linux

Debian 8 (jessie), and Fedora 24 through 28 are not officially supported, even though they still probably work.
Other operating systems are *unsupported*, because of packaging and default configuration differences.

Usage
-----

Standard Ansible Playbooks procedure. [Install Ansible](https://docs.ansible.com/ansible/intro_installation.html), edit the applicable configuration in `group_vars`, put hostnames in `hosts` (the first line is `[nginx-uwsgi]` and the following lines are `hostnames`; default is to install on localhost) and run:

    $ ansible-playbook nginx-uwsgi.yml -i hosts

(You may want to add the ``-K`` option to be asked for the sudo password.)

To understand what the Playbook does, make sure to read the [pyweb tutorial][].

Configuration
-------------

Configuration happens in three files: `hosts`, `group_vars/all`, and `group_vars/os_<destination OS>`.

### Global (`all`)

* `app_name`: the application name, used for configuration files (default: `myapp`)
* `app_package`, `app_callable`: WSGI module to use (default: `flaskapp`, `app`)

  | Framework | Flask, Bottle | Django | Pyramid    |
  |-----------|---------------|--------|------------|
  | Package  | module where `app` is defined | <code><em>project</em>.wsgi</code> (<code><em>project</em></code> is the package with `settings.py`) | module where `app` is defined |
  | Callable | Flask: `app` instance<br>Bottle: `app = bottle.default_app()` | `application` | `app = config.make_wsgi_app()` |
  | Module   | <code><em>package</em>:app</code> | <code><em>project</em>.wsgi:application</code> | <code><em>package</em>:app</code> |
  | Caveats  | Make sure app is **not** in an `if __name__ == '__main__':` block | Add environment variable for settings:<br><code>env = DJANGO_SETTINGS_MODULE=project.settings</code> | Make sure app is **not** in an `if __name__ == '__main__':` block (the demo quickstart does that!) |

* `base_dir`: the base directory (and virtual environment) for the app (default: `/srv/myapp`)
* `appdata_dir`: the directory where app data files reside (default: `{{ base_dir }}/appdata`)
* `nginx_server_name`: hostnames the website is accessible under (default: `localhost myapp.local`)
* `nginx_http_port`: port to use when serving HTTP (default: `80`)
* `uwsgi_module`: WSGI module to use (constructed from `app_package`, `app_callable` — leave it as-is)
* `uwsgi_processes` and `uwsgi_threads`: control the resources devoted to this application. (default: `1` and `1`; should be more for bigger apps)
* `uwsgi_env`: list of environment variables to pass to the app (in key=value format; default: empty)
* `git_repo`: Git repository that contains app code (default: `https://github.com/Kwpolska/flask-demo-app`)
* `git_branch`: Git branch to pull from (default: `master`)
* `nginx_hostless_global_config`: Replace nginx.conf with one that does not have a default host. Destructive, see caveat below! (default: `no`)

### Global with different values for every OS

* `uid`: user used for files and sockets
* `gid`: group used for files and sockets
* `nginx_dir`: nginx sites directory (conf.d or sites-enabled)
* `uwsgi_dir`: uWSGI vassals directory
* `uwsgi_plugins`: uWSGI plugins (`python3,logfile` or `python`)
* `uwsgi_service_name`: uWSGI systemd service name (`uwsgi` or `emperor.uwsgi`)

### OS-specific

* `nginx_patch_confd_Archlinux`: patch `/etc/nginx/nginx.conf` to use `conf.d` (default: `yes`; may fail)
* `nginx_disable_default_site`: disable the default site by removing `/etc/nginx/sites-enabled/default` (default: `yes`; for Debian/Ubuntu)
* `skip_selinux`: skip SELinux tasks (default: `no`; for CentOS/Fedora)

Caveats
-------

### Special dependencies

Make sure you have the following packages installed first on the *destination* machine (Ansible dependencies):

* Debian/Ubuntu: `python`
* Fedora: `python2 python2-dnf libselinux-python`
* CentOS: `python libselinux-python`
* Arch Linux: `python2`

### nginx default site configuration (All OSes)

The default config of nginx creates some servers with default pages. Not everyone wants that. If you want this playbook to *replace* your nginx.conf file with one that has no servers (based on your OSes default `nginx.conf`), set `nginx_hostless_global_config` to `yes`. You should not use it if you customized /etc/nginx/nginx.conf in any way, or if you have installed and configured nginx before. On Ubuntu and Debian, `nginx_disable_default_site` is less destructive and enabled by default.

### nginx host config is very basic — HTTPS needs extra work (All OSes)

The nginx host config is rudimentary and does not include SSL/TLS support and custom error pages. For the former, see [Remy van Elst’s guide](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html).

### nginx conf.d support (Arch Linux)

By default, nginx on Arch Linux does not have any modular-include config directory. This playbook (and best practices) recommend having one for cleaner config. This playbook will try to patch your configuration file, but if you configured nginx in a way that makes the patch fail, you need to manually add this snippet to your `server {}` block:

```nginx
# Load modular configuration files from the /etc/nginx/conf.d directory.
# See http://nginx.org/en/docs/ngx_core_module.html#include
# for more information.
include /etc/nginx/conf.d/*;
```

Afterwards, disable patching — set `nginx_patch_confd_Archlinux` to `no`. You should also disable this patch if you already used this playbook, or have a modular configuration directory already (you can change the path in config).

### Virtual environments use symlinks

If you’re installing to a place that doesn’t like symlinks — for example, a VM
shared folder (eg. ``/vagrant``) on a Windows host, you may get a *Protocol
error* pointing to a ``os.symlink`` call. You can fix this by amending the venv
command to use ``--copy``, or by using a more reasonable place to store your
virtual environment (a Unix filesystem, that is).

License
-------

Copyright © 2016-2021, Chris Warrick.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the author of this software nor the names of contributors to this software may be used to endorse or promote products derived from this software without specific prior written consent.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
