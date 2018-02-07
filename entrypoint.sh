#! /bin/bash

# This script will be run as the ENTRYPOINT of xCAT docker image
# to start xcatd and depended services

# Export the xCAT default Env variables

. /etc/profile.d/xcat.sh

#verify whether $DST is bind mount from $SRC
#function isBINDMOUNT {
#    local SRC=$1
#    local DST=$2
#    SRC=$(echo "$SRC" | sed -r 's/\/$//')
#    findmnt -n $DST | awk -F' ' '{print $2}' | grep -E "\[.*$SRC\]" >/dev/null 2>&1 && return 0
#    return 1
#}


#mkdir -p /install/postscripts/ && \
#     isBINDMOUNT /opt/xcat/postscripts/  /install/postscripts/ || \
#     mount -o bind /opt/xcat/postscripts/ /install/postscripts/
#
#
#mkdir -p /install/prescripts/ && \
#     isBINDMOUNT /opt/xcat/prescripts/  /install/prescripts/ || \
#     mount -o bind /opt/xcat/prescripts/ /install/prescripts/

chown -R root: /var/log/xcat/ 
     
#/dev/loop0 and /dev/loop1 will be occupiered by docker by default
#create a loop device if there is no free loop device inside contanier
losetup -f >/dev/null 2>&1 || (
  maxloopdev=$(losetup -a|awk -F: '{print $1}'|sort -f -r|head -n1);
  maxloopidx=$[${maxloopdev/#\/dev\/loop}];
  mknod /dev/loop$[maxloopidx+1] -m0660 b 7 $[maxloopidx+1] && echo "no free loop device inside container,created a new loop device /dev/loop$[maxloopidx+1]..."
)

echo "restarting http service..."
systemctl start httpd.service

echo "restarting ssh service..."
systemctl start sshd.service

echo "restarting dhcpd service..."
systemctl start dhcpd.service

echo "restarting rsyslog service..."
systemctl start rsyslog.service

echo "restarting xcatd service..."
systemctl start xcatd.service

if [ -e "/etc/NEEDINIT"  ]; then
    echo "initializing xCAT Tables..."
    xcatconfig -d

    #chdef -t site -o clustersite domain="$clusterdomain"
    echo "initializing networks table..."
    tabprune networks -a 
    makenetworks
    
    rm -f /etc/NEEDINIT
fi


#restore the backuped db on container start to resume the service state
if [ -d "/.dbbackup" ]; then   
        echo "xCAT DB backup directory \"/.dbbackup\" detected, restoring xCAT tables from /.dbbackup/..." 
        restorexCATdb -p /.dbbackup/ 
        echo "finished xCAT Tables restore!"
fi

. /etc/profile.d/xcat.sh

cat /etc/motd
HOSTIPS=$(ip -o -4 addr show up|grep -v "\<lo\>"|xargs -I{} expr {} : ".*inet \([0-9.]*\).*")
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "welcome to Dockerized xCAT, please login with"
[ -n "$HOSTIPS"  ] && for i in $HOSTIPS;do echo "   ssh root@$i   ";done && echo "The initial password is \"cluster\""
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


#read -p "press any key to continue..." 
/bin/bash
