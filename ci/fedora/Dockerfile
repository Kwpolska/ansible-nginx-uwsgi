ARG OS_VERSION=latest
FROM fedora:$OS_VERSION
RUN dnf install -y ansible openssh-server openssh-clients curl sudo
RUN /usr/libexec/openssh/sshd-keygen rsa && /usr/libexec/openssh/sshd-keygen ecdsa && /usr/libexec/openssh/sshd-keygen ed25519
RUN ssh-keygen -q -N "" -f /root/.ssh/id_rsa && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN /usr/sbin/sshd && sleep 2 && ssh-keyscan localhost > /root/.ssh/known_hosts && kill $(cat /run/sshd.pid)
RUN mkdir /workspace
ENTRYPOINT ["/repo/ci/entrypoint.sh", "fedora"]
