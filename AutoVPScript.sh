#!/bin/bash
# Script by M4rshall
# ==================================================

# Check IP
MYIP=$(wget -qO- ipv4.icanhazip.com);
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

# STunnel Details
country=PH
state=Manila
locality=Manila
organization=NinjaVPN
organizationalunit=NinjaVPN
commonname=server
email=admin@ninjavpn.tk

# Go To Root
cd

# Disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# Install wget and curl
apt-get update;apt-get -y install wget curl;

# Set Timezone to Manila
ln -fs /usr/share/zoneinfo/Asia/Manila /etc/localtime

# Set Locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# Set Repository
wget -O /etc/apt/sources.list "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/sources.list.debian7"
wget "http://www.dotdeb.org/dotdeb.gpg"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# Remove Some Unused Applications
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# Update Distro
apt-get update; apt-get -y upgrade;

# Install Nginx
apt-get -y install nginx

# Install Essential Package
apt-get -y install nano iptables dnsutils openvpn screen whois ngrep unzip unrar

echo "clear" >> .bashrc
echo 'echo -e "Welcome to your Server"' >> .bashrc
echo 'echo -e "Script Mod by M4rshall"' >> .bashrc
echo 'echo -e "Type menu to display a list of commands"' >> .bashrc
echo 'echo -e ""' >> .bashrc

# Setup Nginx
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/nginx.conf"
mkdir -p /usr/share/m4rshall
echo "" > /usr/share/m4rshall/index.html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/vps.conf"
service nginx restart

# Install OpenVPN
wget -O /etc/openvpn/openvpn.tar "https://github.com/m4rsh4ll/OCSAutoScript/master/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/server.conf "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/server.conf"
rm openvpn.tar
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables_yg_baru_dibikin.conf
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/iptables"
chmod +x /etc/network/if-up.d/iptables
service openvpn restart

# Configure OpenVPN
cd /etc/openvpn/
wget -O /etc/openvpn/client.ovpn "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/client.conf"
sed -i $MYIP2 /etc/openvpn/client.ovpn;
cp client.ovpn /usr/share/m4rshall/

# Install BadVPN
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Setup OpenSSH
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/#Banner/Banner/g' /etc/ssh/sshd_config
service ssh restart

# Install DropBear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=8443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 8888"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# Install Squid Proxy
cd
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/squid.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart

# Install WebMin
cd
apt-get -y install webmin
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart

# Install STunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1


[dropbear]
accept = 8443
connect = 127.0.0.1:8888

END

# Generate STunnel Certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# Configure STunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

# Install LOLCAT with Ruby
apt-get -y install ruby
gem install lolcat

# Install fail2ban;
apt-get -y install fail2ban;service fail2ban restart

# Install AntiDDOS
cd
apt-get -y install dnsutils dsniff
wget https://raw.githubusercontent.com/Clrkz/VPSAutoScrptz/master/ddos-deflate-master.zip 
unzip ddos-deflate-master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/ddos-deflate-master.zip 

# Remove Banner
wget -O /etc/issue.net "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/issue.net"
sed -i 's@#Banner@Banner@g' /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear
service ssh restart
service dropbear restart

# Install XML-Parser
cd
yes yes | apt-get libxml-parser-perl

# Download Scripts
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/menu.sh"
wget -O usernew "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/usernew.sh"
wget -O trial "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/trial.sh"
wget -O delete "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/delete.sh"
wget -O check "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/user-login.sh"
wget -O member "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/user-list.sh"
wget -O restart "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/info.sh"
wget -O about "https://raw.githubusercontent.com/m4rsh4ll/OCSAutoScript/master/about.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x usernew
chmod +x trial
chmod +x delete
chmod +x check
chmod +x member
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about

# Finalizing
cd
chown -R www-data:www-data /usr/share/m4rshall
service nginx start
service openvpn restart
service cron restart
service ssh restart
service dropbear restart
service squid3 restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# install neofetch
echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch

echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch

# info
clear
echo "Autoscript Include:" | tee log-install.txt
echo "===========================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "OpenSSH  : 22"  | tee -a log-install.txt
echo "Dropbear : 8443, 8888"  | tee -a log-install.txt
echo "SSL      : 8888"  | tee -a log-install.txt
echo "Squid3   : 8000, 8080 (limit to IP SSH)"  | tee -a log-install.txt
echo "OpenVPN  : TCP 443"  | tee -a log-install.txt
echo "badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "Webmin   : http://$MYIP:10000/"  | tee -a log-install.txt
echo "Timezone : Asia/Manila (GMT +8)"  | tee -a log-install.txt
echo "IPv6     : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "VPS AUTO REBOOT TIME HOURS 12 NIGHT"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==========================================="  | tee -a log-install.txt
cd
rm -f /root/AutoVPScript.sh
