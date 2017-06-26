
FROM centos:latest

MAINTAINER drdukes@gmail.com

VOLUME ["/install","/var/log/xcat/","/sys/fs/cgroup"]

ENV container docker
COPY startservice-centos.sh /bin/startservice.sh 
COPY patch.bin.stop /sbin/stop
COPY motd /etc/motd

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
        systemd-tmpfiles-setup.service ] || rm -f $i; done); \
        rm -f /lib/systemd/system/multi-user.target.wants/*;\
        rm -f /etc/systemd/system/*.wants/*;\
        rm -f /lib/systemd/system/local-fs.target.wants/*; \
        rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
        rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
        rm -f /lib/systemd/system/basic.target.wants:/*;\
        rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN yum clean all && yum install -y \
	    iproute \
        less \
        openssh-server \
        rsyslog \
        wget; \
        wget -O - \
        "https://raw.githubusercontent.com/xcat2/xcat-core/master/xCAT-server/share/xcat/tools/go-xcat" \
        >/tmp/go-xcat ; \
        chmod +x /tmp/go-xcat ; \
        /tmp/go-xcat --yes install ; \
        chmod +x /bin/startservice.sh; \
        chmod +x /sbin/stop; \
        [ -e "/etc/ssh/sshd_config" ] \
        && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config ;\
        sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config ;\
        echo "root:cluster" | chpasswd \
        touch /etc/NEEDINIT

CMD ["/usr/sbin/init","/bin/startservice.sh"]
ENTRYPOINT [ "sh", "-c" ]
