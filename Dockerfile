FROM nginx:stable

RUN apt-get update && apt-get install -y openssh-server
RUN apt-get install -y git
RUN apt-get install -y tree
RUN apt-get install -y vim
RUN apt-get install -y tmux

RUN groupadd sshgroup && useradd -ms /bin/bash -g sshgroup wcarhart
RUN echo 'wcarhart:password' | chpasswd
COPY id_rsa.pub $home/.ssh/authorized_keys

ARG home=/home/wcarhart
RUN mkdir $home/.ssh

RUN mkdir $home/aerogram
COPY aerogram.sh $home/aerogram/
COPY aerogram_renderer.sh $home/aerogram/
COPY aerogram_listener.sh $home/aerogram/

RUN chmod 766 $home

CMD service ssh start && nginx -g 'daemon off;'
