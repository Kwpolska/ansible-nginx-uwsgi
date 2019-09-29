# Continuous Integration for ansible-nginx-uwsgi

This directory contains Docker containers and a test harness to test the
Ansible Playbook in this repository. Note that there are a few deviations from
the standard setup due to how Docker works:

* no systemd
* not using `setuid`/`setgid`
* running uwsgi manually, with `sudo -u $USER`

Nevertheless, many configuration failures can be caught by this process.
