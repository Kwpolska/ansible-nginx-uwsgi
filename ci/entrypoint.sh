#!/bin/bash
OS=$1
echo "Running CI script, OS=$OS"
UWSGI_EXTRA_ARGS=''
case $OS in
    fedora | centos)
        UWSGI_USER=uwsgi
        SOCKET_GROUP=nginx
        UWSGI_INI=/etc/uwsgi.ini
        ;;
    ubuntu | debian)
        UWSGI_USER=www-data
        SOCKET_GROUP=www-data
        UWSGI_INI=/etc/uwsgi-emperor/emperor.ini
        UWSGI_EXTRA_ARGS='--pidfile /run/uwsgi/uwsgi.pid';;
    archlinux)
        UWSGI_USER=http
        SOCKET_GROUP=http
        UWSGI_INI=/etc/uwsgi/emperor.ini
        UWSGI_EXTRA_ARGS='--pidfile /run/uwsgi/uwsgi.pid';;
    *) echo "Unknown OS"; exit 5;;
esac
set -ex
/usr/sbin/sshd
cp -rf /repo/* /workspace
cd /workspace
cp ci/ignore_systemd.yml roles/start_services/tasks/main.yml
if [[ "$OS" == "archlinux" ]]; then
    sed 's/nginx_hostless_global_config: no/nginx_hostless_global_config: yes/' group_vars/all -i
fi
if [[ "$OS" == "fedora" ]]; then
    grep -q 29 /etc/fedora-release && ANSIBLE_EXTRA_ARGS='-u root' || true
fi
ansible-playbook -i hosts nginx-uwsgi.yml $ANSIBLE_EXTRA_ARGS
kill $(cat /run/sshd.pid)
nginx
mkdir -p /run/uwsgi
cat $UWSGI_INI | grep -Pv '^(uid|gid|cap) = ' > patched-uwsgi.ini
chown $UWSGI_USER:$SOCKET_GROUP /run/uwsgi
sudo -u $UWSGI_USER uwsgi --ini patched-uwsgi.ini $UWSGI_EXTRA_ARGS &

COUNTER=0
MAX_COUNT=10
SLEEP_LENGTH=2
echo "Waiting $MAX_COUNT seconds for uwsgi to become available..."
while [[ ! -S /srv/myapp/uwsgi.sock && $COUNTER -lt $MAX_COUNT ]]; do
    sleep $SLEEP_LENGTH
    COUNTER=$[COUNTER+SLEEP_LENGTH]
done
if [[ ! -S /srv/myapp/uwsgi.sock ]]; then
    echo "uwsgi failed to start"
    exit 2
fi

chown $UWSGI_USER:$SOCKET_GROUP /srv/myapp/uwsgi.sock
curl -v localhost
curl localhost -o localhost-output
curl localhost/static/hello.png -o png-output
set +x
grep -q 'Hello from Flask!' localhost-output
if [[ $? -ne 0 ]]; then echo "Failed to find Flask output"; exit 3; else echo "Output OK"; fi
grep -qz $(echo -e "^\x89PNG") png-output
if [[ $? -ne 0 ]]; then echo "Failed to find favicon served by nginx"; exit 4; else echo "Static OK"; fi

echo "Cleaning up..."
kill $(cat /run/nginx.pid)
kill -SIGQUIT $(cat /run/uwsgi/uwsgi.pid)
sleep 1
echo "Build succeeded."
exit 0
