#!/usr/bin/env bash

# Definição  nome e email para uso no git.
nome_git="Leonardo Bruno"
email_git="souzalb@proton.me"

# Definição do arquivo iso.
arquivo_iso="./iso/debian-12.7.0-amd64-STICK16GB-1.iso"
pasta_config="./config"

# Definição do log.
mkdir -p "./log"
exec > >(tee -a "./log/debian12.log")
exec 2>&1

# Marca início da execução.
echo "[ INFO - início da execução - $(date) ]"

# Teste de conectividade.
if ! ping -c 1 www.google.com.br &> /dev/null; then
    echo "[ ERRO - falha na conexão - $(date) ]"
    echo "[ INFO - fim execução - $(date) ]"
    exit 1
fi
echo "[ INFO - conexão ok - $(date) ]"

# Ajuste na timezone.
timezone_atual=$(timedatectl show --property=Timezone | cut -d'=' -f2)
if [ "$timezone_atual" != "America/Sao_Paulo" ]; then
    sudo timedatectl set-timezone America/Sao_Paulo
    echo "[ INFO - timezone ok $(date) ]"
fi

# Função para cópia de arquivos usando sudo e backup.
cp_arquivo_sudo(){
    local arquivo_backup="$1"
    local arquivo="$2"
    local arquivo_config="$3"
    if [ ! -f "$arquivo_backup" ]; then
        sudo mv "$arquivo" "$arquivo_backup"
        sudo cp "$arquivo_config" "$arquivo"
        echo "[ INFO - $(basename "$arquivo") ok - $(date) ]"
    fi
}

# Função para cópia de arquivos.
cp_arquivo(){
    local arquivo="$1"
    local arquivo_config="$2"
    if [ ! -f "$arquivo" ]; then
        cp "$arquivo_config" "$arquivo"
        echo "[ INFO - $(basename "$arquivo") ok - $(date) ]"
    fi
}

# Função para cópia de arquivos com backup.
cp_arquivo_backup(){
    local arquivo_backup="$1"
    local arquivo="$2"
    local arquivo_config="$3"
    if [ ! -f "$arquivo_backup" ]; then
        mv "$arquivo" "$arquivo_backup"
        cp "$arquivo_config" "$arquivo"
        echo "[ INFO - $(basename "$arquivo") ok - $(date) ]"
    fi
}

# Ajuste touchpad no Xorg.
cp_arquivo_sudo "/usr/share/X11/xorg.conf.d/40-libinput.conf.backup" "/usr/share/X11/xorg.conf.d/40-libinput.conf" "$pasta_config/40-libinput.conf"

# Ajuste no grub.
cp_arquivo_sudo "/etc/default/grub.backup" "/etc/default/grub" "$pasta_config/grub"
sudo update-grub

# Ajuste no gerenciamento de energia.
cp_arquivo_sudo "/etc/UPower/UPower.conf.backup" "/etc/UPower/UPower.conf" "$pasta_config/UPower.conf"
cp_arquivo_sudo "/etc/systemd/logind.conf.backup" "/etc/systemd/logind.conf" "$pasta_config/logind.conf"
cp_arquivo_backup "$HOME/.bashrc.backup" "$HOME/.bashrc" "$pasta_config/bashrc"

# Instala pacotes e configura o sources.
sources_list_backup="/etc/apt/sources.list.backup"
sources_list="/etc/apt/sources.list"

if [ ! -f "$sources_list_backup" ]; then
    sudo mount "$arquivo_iso" /media/cdrom
    sudo apt-cdrom -m add

    # Instala pacotes incluídos no iso.
    sudo apt-get install -y \
        vim tmux htop links curl speedtest-cli \
        gddrescue testdisk gparted gsmartcontrol galculator gtkhash imagemagick \
        libcupsimage2 gimp inkscape libreoffice-base audacity \
        geany bluefish meld spyder git gcc g++ make gdb openjdk-17-jdk \
        maven python3-pip python3-virtualenv jupyter r-base npm \
        lua5.4 sqlite3 virt-manager docker.io docker-compose \
        greybird-gtk-theme papirus-icon-theme

    sudo umount /media/cdrom
    echo "[ INFO - pacotes iso ok - $(date) ]"

    cp_arquivo_sudo "$sources_list_backup" "$sources_list" "$pasta_config/sources.list"
    sudo apt-get update

    # Instala pacotes do repositório da internet.
    sudo apt-get install -y jigdo-file dc3dd mednafen
    echo "[ INFO - pacotes extras ok - $(date) ]"
fi

# Configura o lightdm.
cp_arquivo_sudo "/etc/lightdm/lightdm.conf.backup" "/etc/lightdm/lightdm.conf" "$pasta_config/lightdm.conf"
cp_arquivo_sudo "/etc/lightdm/lightdm-gtk-greeter.conf.backup" "/etc/lightdm/lightdm-gtk-greeter.conf" "$pasta_config/lightdm-gtk-greeter.conf"

# Configura o XFCE4.
whiskermenu="$HOME/.config/xfce4/panel/whiskermenu-1.rc"
if [ ! -f "$whiskermenu" ]; then
    xfconf-query -c xfwm4 -p /general/vblank_mode -s glx
    xfconf-query -c xsettings -p /Xft/Antialias -s 1
    xfconf-query -c xsettings -p /Xft/Hinting -s 1
    xfconf-query -c xsettings -p /Xft/HintStyle -s hintfull
    xfconf-query -c xsettings -p /Xft/RGBA -s rgb
    xfconf-query -c xsettings -p /Net/ThemeName -s Greybird-dark
    xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-Dark
    xfconf-query -c xfwm4 -p /general/theme -s Greybird-dark
    xfconf-query -c xfce4-panel -p /panels/dark-mode -s true
    xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s whiskermenu
    cp_arquivo "$whiskermenu" "$pasta_config/whiskermenu-1.rc"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -s xfce4-popup-whiskermenu -n -t string
    xfce4-panel -r
    xfconf-query -c pointers -p /SynPS2_Synaptics_TouchPad/Properties/libinput_Tapping_Enabled -n -t int -s 1
    echo "[ INFO - xfce4 ok - $(date) ]"
fi

# Configuração editores de terminal.
cp_arquivo "$HOME/.nanorc" "$pasta_config/nanorc"
mkdir -p $HOME/.vim/{arquivos-backup,arquivos-swap,arquivos-undo}
cp_arquivo "$HOME/.vimrc" "$pasta_config/vimrc"

# Configuração geany.
mkdir -p ~/.config/geany/colorschemes/
cp_arquivo "$HOME/.config/geany/geany.conf" "$pasta_config/geany.conf"
cp_arquivo "$HOME/.config/geany/colorschemes/one-dark.conf" "$pasta_config/one-dark.conf"

# Configuração bluefish.
mkdir -p ~/.bluefish
cp_arquivo "$HOME/.bluefish/rcfile-2.0" "$pasta_config/rcfile-2.0"

# Configuração zeal.
mkdir -p ~/.config/Zeal
cp_arquivo "$HOME/.config/Zeal/Zeal.conf" "$pasta_config/Zeal.conf"

# Configuração terminal.
mkdir -p ~/.config/xfce4/terminal/
cp_arquivo "$HOME/.config/xfce4/terminal/terminalrc" "$pasta_config/terminalrc"

# Configuração git.
if [ ! -f "$HOME/.gitconfig" ]; then
    git config --global user.name "$nome_git"
    git config --global user.email "$email_git"
    git config --global core.editor "vim"
    echo "[ INFO - git ok - $(date) ]"
fi

# Configuração Jupyter Notebook.
if [ ! -d "$HOME/ambiente-jupyter" ]; then
    virtualenv "$HOME/ambiente-jupyter"
    mkdir -p "$HOME/notebooks-jupyter"
    source "$HOME/ambiente-jupyter/bin/activate"
    pip install --upgrade pip
    pip install ipykernel jupyterthemes==0.20.0
    python3 -m ipykernel install --user --name=ambiente-jupyter
    jt -t onedork -T -N -kl
    deactivate
    echo "[ INFO - jupyter ok - $(date) ]"
fi

# Adiciona usuário corrente ao grupo Docker.
sudo usermod -aG docker $(whoami)
echo "[ INFO - docker ok - $(date) ]"

# Marca o fim da execução.
echo "[ INFO - fim da execução - $(date) ]"
