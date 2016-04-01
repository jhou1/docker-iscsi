FROM fedora:22
MAINTAINER Jianwei Hou, jhou@redhat.com

RUN dnf install -y targetcli
RUN systemctl enable target

ADD init.sh /

ENTRYPOINT /init.sh
