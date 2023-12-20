#!/bin/bash
# Script por Jeanpseven (wrench)
# GitHub: jeanpseven

# Função para escolher um IP disponível na sub-rede 192.168.1.x
choose_available_ip() {
    local base_ip="192.168.1"
    local suffix=2

    while true; do
        local ip_to_check="$base_ip.$suffix"
        if ! ping -c 1 -W 1 $ip_to_check &>/dev/null; then
            echo "$ip_to_check"
            break
        fi
        ((suffix++))
    done
}

# Listar diretórios disponíveis
echo "Diretórios disponíveis:"
directories=($(find . -maxdepth 1 -type d -printf "%f\n"))

# Exibir lista numerada
for ((i=0; i<${#directories[@]}; i++)); do
    echo "$((i+1)). ${directories[i]}"
done

# Solicitar escolha do usuário
while true; do
    read -p "Escolha o número do diretório a ser hospedado: " choice
    if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#directories[@]} ]]; then
        selected_dir=${directories[choice-1]}
        break
    else
        echo "Escolha inválida. Tente novamente."
    fi
done

# Solicitar informações do usuário
read -p "Digite o nome da interface Wi-Fi: " interface
read -p "Digite o nome da rede (SSID): " ssid
read -p "Digite a senha da rede (ou deixe em branco para uma rede aberta): " password

# Escolher automaticamente um IP disponível
ip_address=$(choose_available_ip)

# Configurar hostapd
cat <<EOL | sudo tee /etc/hostapd/hostapd.conf > /dev/null
interface=$interface
ssid=$ssid
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOL

if [ -n "$password" ]; then
    cat <<EOL | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
wpa=2
wpa_passphrase=$password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL
fi

# Mudar para o diretório selecionado
cd "$selected_dir"

# Iniciar um servidor HTTP simples para hospedar o diretório
python3 -m http.server 80

echo "Configuração concluída! Seu diretório '$selected_dir' está sendo hospedado em http://$ip_address"
