FROM ubuntu:22.04
RUN apt update && apt install openssh-server sudo -y \
    && useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ubuntu \
    && echo 'ubuntu:ubuntu' | chpasswd \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && mkdir /home/ubuntu/.ssh
COPY ./ed.pub /home/ubuntu/.ssh/ed.pub
RUN cat /home/ubuntu/.ssh/ed.pub >> /home/ubuntu/.ssh/authorized_keys \
    && chmod -R go= /home/ubuntu/.ssh \
    && chown -R ubuntu /home/ubuntu/.ssh \
    &&  service ssh start
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]