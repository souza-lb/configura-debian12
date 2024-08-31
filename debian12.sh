#!/usr/bin/env bash

# Definir o nome e e-mail para uso no git
nome_git="Leonardo Bruno"
email_git="souzalb@proton.me"

# Definir caminhos
pasta_log="./log"
arquivo_log="$pasta_log/log.log"
arquivo_iso="./iso/debian-12.6.0-amd64-STICK16GB-1.iso"
pasta_config="./config"

# Criar pasta de log se não existir
mkdir -p "$pasta_log"

# Redirecionar saídas para o arquivo de log
exec > >(tee -a "$arquivo_log")
exec 2>&1

# Função para backup e configuração de arquivos
configurar_arquivo() {
    local arquivo_backup="$1"
    local arquivo="$2"
    local arquivo_config="$3"
    if [ ! -f "$arquivo_backup" ]; then
        sudo mv "$arquivo" "$arquivo_backup"
        sudo cp "$arquivo_config" "$arquivo"
        echo "[ $(basename "$arquivo") configurado ]"
    else
        echo "[ $(basename "$arquivo") já configurado ]"
    fi
}

# Marcar início da execução
clear
echo "[ início execução ]"
echo "[ $(date) ]"

# Testar conectividade
if ! ping -c 1 google.com &> /dev/null; then
    echo "[ verifique sua conexão com a internet! ]"
    echo "[ fim execução ]"
    echo "[ $(date) ]"
    exit 1
else
    echo "[ conexão com internet funcionando ]"
fi

# Ajustar a timezone
timezone_atual=$(timedatectl show --property=Timezone | cut -d'=' -f2)
if [ "$timezone_atual" != "America/Sao_Paulo" ]; then
    sudo timedatectl set-timezone America/Sao_Paulo
    sudo timedatectl status
    echo "[ timezone configurada ]"
else
    echo "[ timezone já configurada ]"
fi

# Configuração touchpad no Xorg
configurar_arquivo "/usr/share/X11/xorg.conf.d/40-libinput.conf.backup" "/usr/share/X11/xorg.conf.d/40-libinput.conf" "$config_dir/40-libinput.conf"

# Ajustes GRUB
configurar_arquivo "/etc/default/grub.backup" "/etc/default/grub" "$config_dir/grub"
sudo update-grub

# Desabilitar o gerenciamento de energia
configurar_arquivo "/etc/UPower/UPower.conf.backup" "/etc/UPower/UPower.conf" "$config_dir/UPower.conf"

# Ajustes logind
configurar_arquivo "/etc/systemd/logind.conf.backup" "/etc/systemd/logind.conf" "$config_dir/logind.conf"

# Configurar .bashrc
configurar_arquivo "$HOME/.bashrc.backup" "$HOME/.bashrc" "$config_dir/bashrc"

# Instalar pacotes e atualizar sources
sources_list_backup="/etc/apt/sources.list.backup"
sources_list="/etc/apt/sources.list"

if [ ! -f "$sources_list_backup" ]; then
    sudo mount "$iso_file" /media/cdrom
    sudo apt-cdrom -m add

    sudo apt-get install -y vim tmux htop \
        links curl speedtest-cli\
        gddrescue testdisk \
        gparted gsmartcontrol galculator gtkhash imagemagick \
        libcupsimage2 gimp inkscape libreoffice-base audacity \
        geany bluefish meld spyder git gcc g++ make gdb openjdk-17-jdk \
        maven python3-pip python3-virtualenv jupyter r-base npm \
        lua5.4 sqlite3 virt-manager docker.io docker-compose \
        greybird-gtk-theme papirus-icon-theme

    sudo umount /media/cdrom
    echo "[ pacotes instalados ]"

    sudo mv "$sources_list" "$sources_list_backup"
    sudo cp "$config_dir/sources.list" "$sources_list"
    sudo apt-get update
    echo "[ sources configurado ]"
else
    echo "[ sources já configurado ]"
fi

# Ajustes lightdm
configurar_arquivo "/etc/lightdm/lightdm.conf.backup" "/etc/lightdm/lightdm.conf" "$config_dir/lightdm.conf"

# Ajustes lightdm-gtk
configurar_arquivo "/etc/lightdm/lightdm-gtk-greeter.conf.backup" "/etc/lightdm/lightdm-gtk-greeter.conf" "$config_dir/lightdm-gtk-greeter.conf"

# Ajustes XFCE4
whiskermenu="$HOME/.config/xfce4/panel/whiskermenu-1.rc"
if [ ! -f "$whiskermenu" ]; then
    echo "[ xfce4 iniciando configuração ]"
    xfconf-query -c xfwm4 -p /general/vblank_mode -s glx
    xfconf-query -c xsettings -p /Xft/Antialias -s 1
    xfconf-query -c xsettings -p /Xft/Hinting -s 1
    xfconf-query -c xsettings -p /Xft/HintStyle -s hintfull
    xfconf-query -c xsettings -p /Xft/RGBA -s rgb
    echo "[ xfce4 fontes configuradas ]"

    xfconf-query -c xsettings -p /Net/ThemeName -s Greybird-dark
    xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-Dark
    xfconf-query -c xfwm4 -p /general/theme -s Greybird-dark
    xfconf-query -c xfce4-panel -p /panels/dark-mode -s true
    echo "[ xfce4 temas configurados ]"

    xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s whiskermenu
    cp "$config_dir/whiskermenu-1.rc" "$whiskermenu"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -s xfce4-popup-whiskermenu -n -t string
    xfce4-panel -r
    echo "[ xfce4 whiskermenu configurado ]"

    xfconf-query -c pointers -p /SynPS2_Synaptics_TouchPad/Properties/libinput_Tapping_Enabled -n -t int -s 1
    echo "[ xfce4 touchpad configurado ]"
else
    echo "[ xfce4 já configurado ]"
fi

# Configurar .nanorc
configurar_arquivo "$HOME/.nanorc" "$HOME/.nanorc" "$config_dir/nanorc"

# Configurar .vimrc
vimrc="$HOME/.vimrc"
if [ ! -f "$vimrc" ]; then
    mkdir -p "$HOME/.vim/{arquivos-backup,arquivos-swap,arquivos-undo}"
    cp "$config_dir/vimrc" "$vimrc"
    echo "[ vimrc configurado ]"
else
    echo "[ vimrc já configurado ]"
fi

# Configurar Geany
configurar_arquivo "$HOME/.config/geany/geany.conf" "$HOME/.config/geany/geany.conf" "$config_dir/geany.conf"
configurar_arquivo "$HOME/.config/geany/colorschemes/one-dark.conf" "$HOME/.config/geany/colorschemes/one-dark.conf" "$config_dir/one-dark.conf"

# Configurar Bluefish
configurar_arquivo "$HOME/.bluefish/rcfile-2.0" "$HOME/.bluefish/rcfile-2.0" "$config_dir/rcfile-2.0"

# Configurar xfce4-terminal
configurar_arquivo "$HOME/.config/xfce4/terminal/terminalrc" "$HOME/.config/xfce4/terminal/terminalrc" "$config_dir/terminalrc"

# Configurar Git
config_git="$HOME/.gitconfig"
if [ ! -f "$config_git" ]; then
    git config --global user.name "$nome_git"
    git config --global user.email "$email_git"
    git config --global core.editor "vim"
    echo "[ git configurado ]"
else
    echo "[ git já configurado ]"
fi

# Configurar Jupyter Notebook
ambiente_jupyter="$HOME/ambiente-jupyter"
if [ ! -d "$ambiente_jupyter" ]; then
    virtualenv "$ambiente_jupyter"
    mkdir -p "$HOME/notebooks-jupyter"
    source "$ambiente_jupyter/bin/activate"
    pip install --upgrade pip
    pip install ipykernel
    python3 -m ipykernel install --user --name=ambiente-jupyter
    pip install jupyterthemes==0.20.0
    jt -t on
else
    echo "[ jupyter notebook já configurado ]"
fi

# marca fim da execução.
echo "[ fim execução ]"
echo "[ $( date ) ]"