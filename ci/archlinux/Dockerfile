ARG OS_VERSION=latest
FROM archlinux:$OS_VERSION
RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm ansible openssh sudo python curl patch sed
RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -q -N "" -f /root/.ssh/id_rsa && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN /usr/sbin/sshd && sleep 2 && ssh-keyscan localhost > /root/.ssh/known_hosts && kill $(cat /run/sshd.pid)
RUN mkdir /workspace
ENTRYPOINT ["/repo/ci/entrypoint.sh", "archlinux"]
