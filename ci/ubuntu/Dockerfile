ARG OS_VERSION=latest
FROM ubuntu:$OS_VERSION
RUN apt-get update
RUN apt-get install -y ansible openssh-server openssh-client sudo python curl
RUN ssh-keygen -q -N "" -f /root/.ssh/id_rsa && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN mkdir /run/sshd && /usr/sbin/sshd && sleep 2 && ssh-keyscan localhost > /root/.ssh/known_hosts && kill $(cat /run/sshd.pid)
RUN mkdir /workspace
ENTRYPOINT ["/repo/ci/entrypoint.sh", "ubuntu"]
