ARG OS_VERSION=latest
FROM centos:$OS_VERSION
RUN yum install -y epel-release
RUN yum install -y ansible openssh-server openssh-clients sudo
RUN ssh-keygen -A
RUN ssh-keygen -q -N "" -f /root/.ssh/id_rsa && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN /usr/sbin/sshd && sleep 2 && ssh-keyscan localhost > /root/.ssh/known_hosts && kill $(cat /run/sshd.pid)
RUN mkdir /workspace
ENTRYPOINT ["/repo/ci/entrypoint.sh", "centos"]
