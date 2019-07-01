FROM nginx:stable

RUN apt-get update && apt-get install -y openssh-server
RUN apt-get install -y git
RUN apt-get install -y tree
RUN apt-get install -y vim

RUN groupadd sshgroup && useradd -ms /bin/bash -g sshgroup sshuser
RUN echo 'sshuser:password' | chpasswd
COPY ~/id_rsa.pub $home/.ssh/authorized_keys

ARG home=/home/sshuser
RUN mkdir $home/.ssh

CMD service ssh start && nginx -g 'daemon off;'
