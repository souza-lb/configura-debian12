#!/usr/bin/env bash

# Configuração do log.
mkdir -p "./log"
exec > >( tee -a "./log/configura-debian12.log" )
exec 2>&1

echo "[ INFO - inicio da execução - $( date ) ]"

# Teste de conexão.
if ! ping -c 1 www.google.com.br &> /dev/null; then
    echo "[ ERRO - falha na conexão - $( date ) ]"
    echo "[ INFO - fim da execução - $( date ) ]"
    exit 1
fi
echo "[ INFO - conexão ok - $( date ) ]"

# Ajusta a timezone.
timezone_atual=$( timedatectl show --property=Timezone | cut -d'=' -f2 )
if [ $timezone_atual != "America/Sao_Paulo" ]; then
    sudo timedatectl set-timezone America/Sao_Paulo
    echo "[ INFO - timezone ok - $( date ) ]"
fi

# Desabilita o gerenciamento de energia.
upower="/etc/UPower/UPower.conf"
upower_backup="/etc/UPower/UPower.conf.backup"
upower_conf="./config/UPower.conf"
if [ ! -f $upower_backup ]; then
    sudo mv $upower $upower_backup
    sudo cp $upower_conf $upower
    echo "[ INFO - upower ok - $( date )]"
fi
logind="/etc/systemd/logind.conf"
logind_backup="/etc/systemd/logind.conf.backup"
logind_conf="./config/logind.conf"
if [ ! -f $logind_backup ]; then
    sudo mv $logind $logind_backup
    sudo cp $logind_conf $logind
    echo "[ INFO - logind ok - $( date ) ]"
fi
bashrc="$HOME/.bashrc"
bashrc_backup="$HOME/.bashrc.backup"
bashrc_conf="./config/bashrc"
if [ ! -f $bashrc_backup ]; then
    mv $bashrc $bashrc_backup
    cp $bashrc_conf $bashrc
    echo "[ INFO - bashrc ok -$( date ) ]"
fi

# Configura o touchpad no Xorg.
libinput="/usr/share/X11/xorg.conf.d/40-libinput.conf"
libinput_backup="/usr/share/X11/xorg.conf.d/40-libinput.conf.backup"
libinput_conf="./config/40-libinput.conf"
if [ ! -f $libinput_backup ]; then
    sudo mv $libinput $libinput_backup
    sudo cp $libinput_conf $libinput
    echo "[ INFO - libinput ok - $( date ) ]"
fi

# Configura o grub.
grub="/etc/default/grub"
grub_backup="/etc/default/grub.backup"
grub_conf="./config/grub"
if [ ! -f $grub_backup ]; then
    sudo mv $grub $grub_backup
    sudo cp $grub_conf $grub
    sudo update-grub
    echo "[ INFO - grub ok - $( date ) ]"
fi

# Instala pacotes do iso.
sources="/etc/apt/sources.list"
sources_backup="/etc/apt/sources.list.backup"
sources_conf="./config/sources.list"
if [ ! -f "/etc/apt/sources.list.backup" ]; then
    # Monta o iso disponibilizado.
    sudo mount ./iso/debian-12.7.0-amd64-STICK16GB-1.iso /media/cdrom
    # Adiciona arquivos iso na lista repositório.
    sudo apt-cdrom -m add
    sudo apt-get install -y \
        vim tmux htop links curl speedtest-cli \
        gddrescue testdisk gparted gsmartcontrol \
        galculator gtkhash imagemagick \
        libcupsimage2 gimp inkscape \
        libreoffice-base \
        audacity \
        geany bluefish meld git \
        gcc g++ make gdb \
        openjdk-17-jdk maven \
        python3-pip python3-virtualenv \
        jupyter-notebook  \
        r-base \
        npm \
        lua5.4 \
        sqlite3 \
        virt-manager \
        docker.io docker-compose \
        greybird-gtk-theme papirus-icon-theme
    # Desmonta o iso após o uso.
    sudo umount /media/cdrom
    echo "[ INFO - pacotes iso ok - $( date ) ]"
    # Faz backup do sources atual.
    sudo mv $sources $sources_backup
    # Copia o sources já configurado.
    sudo cp $sources_conf $sources
    # Atualiza a lista de pacotes.
    sudo apt-get update 
    echo "[ INFO - sources ok - $( date ) ]"
    # Instala pacotes extras.
    sudo apt-get install -y \
        jigdo-file dc3dd zeal mednafen
    echo [ "INFO - pacotes extras ok - $( date )"]
fi

# Configura o Lighdm.
lightdm="/etc/lightdm/lightdm.conf"
lightdm_backup="/etc/lightdm/lightdm.conf.backup"
lightdm_conf="./config/lightdm.conf"
if [ ! -f $lightdm_backup ]; then
    sudo mv $lightdm $lightdm_backup
    sudo cp $lightdm_conf $lightdm
    echo "[  INFO - lightdm ok - $( date ) ]"
fi
lightdm_gtk="/etc/lightdm/lightdm-gtk-greeter.conf"
lightdm_gtk_backup="/etc/lightdm/lightdm-gtk-greeter.conf.backup"
lightdm_gtk_conf="./config/lightdm-gtk-greeter.conf"
if [ ! -f $lightdm_gtk_backup ]; then
    sudo mv $lightdm_gtk $lightdm_gtk_backup
    sudo cp $lightdm_gtk_conf $lightdm_gtk
    echo "[  INFO - lightdm ok - $( date ) ]"
fi

# Configura o XFCE4.
whiskermenu="$HOME/.config/xfce4/panel/whiskermenu-1.rc"
whiskermenu_conf="./config/whiskermenu-1.rc"
if [ ! -f $whiskermenu ]; then
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
    cp $whiskermenu_conf $whiskermenu
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -s xfce4-popup-whiskermenu -n -t string
    xfce4-panel -r
    xfconf-query -c pointers -p /SynPS2_Synaptics_TouchPad/Properties/libinput_Tapping_Enabled -n -t int -s 1
    echo "[ INFO - xfce4 ok - $( date ) ]"
fi

# Configura o Terminal XFCE4.
terminal="$HOME/.config/xfce4/terminal/terminalrc"
terminal_conf="./config/terminalrc"
if [ ! -f $terminal ]; then
    mkdir -p $HOME/.config/xfce4/terminal/
    cp $terminal_conf $terminal
    echo "[ INFO - terminal ok - $( date ) ]"
fi

# Configuração do Nano.
nano="$HOME/.nanorc"
nano_conf="./config/nanorc"
if [ ! -f $nano ]; then
    cp $nano_conf $nano
    echo "[ INFO - nano ok - $( date ) ]"
fi

# configura o Vim.
vim="$HOME/.vimrc"
vim_conf="./config/vimrc"
if [ ! -f $vim ]; then
    mkdir -p $HOME/.vim/{arquivos-backup,arquivos-swap,arquivos-undo}
    cp $vim_conf $vim
    echo "[ INFO - vim ok - $( date ) ]"
fi

# configura o geany.
geany="$HOME/.config/geany/geany.conf"
geany_conf="./config/geany.conf"
geany_theme="$HOME/.config/geany/colorschemes/one-dark.conf"
geany_theme_conf="./config/one-dark.conf"

if [ ! -f $geany ]; then
  mkdir -p $HOME/.config/geany/colorschemes/
  cp $geany_theme_conf $geany_theme
  cp $geany_conf $geany
  echo "[ INFO - geany ok - $( date ) ]"
fi

# configura o Bluefish.
bluefish="$HOME/.bluefish/rcfile-2.0"
bluefish_conf="./config/rcfile-2.0"

if [ ! -f "$bluefish" ] ; then
  mkdir -p $HOME/.bluefish
  cp $bluefish_conf $bluefish
  echo "[ INFO - bluefish ok - $( date ) ]"
fi

# configura o zeal.
zeal="$HOME/.config/Zeal/Zeal.conf"
zeal_conf="./config/Zeal.conf"

if [ ! -f "$zeal" ] ; then
  mkdir -p ~/.config/Zeal
  cp $zeal_conf "$zeal"
  echo "[ INFO -  zeal ok - $( date ) ]"
fi

# Configuração Git.
if [ ! -f "$HOME/.gitconfig" ]; then
    git config --global user.name "Leonardo Bruno"
    git config --global user.email "souzalb@proton.me"
    git config --global core.editor "vim"
    echo "[ INFO - git ok - $(date) ]"
fi

# Configuração Jupyter Notebook.
if [ ! -d "$HOME/Jupyter/ambientes/padrao" ]; then
    mkdir -p "$HOME/Jupyter/notebooks/padrao"
    virtualenv "$HOME/Jupyter/ambientes/padrao"
    source "$HOME/Jupyter/ambientes/padrao/bin/activate"
    pip install --upgrade pip
    pip install ipykernel jupyterthemes==0.20.0
    python3 -m ipykernel install --user --name=padrao
    jt -t onedork -T -N -kl
    deactivate
    echo "[ INFO - jupyter ok - $(date) ]"
fi

# Adiciona usuário corrente ao grupo Docker.
if ! id -nG $USER | grep -qw "docker"; then
    sudo usermod -aG docker "$USER"
    echo "[ INFO - docker ok - $( date ) ]"
fi

# Define o Firefox-ESR como padrão para abrir HTML.
padrao_atual=$(xdg-mime query default text/html)
if [ $padrao_atual != "firefox-esr.desktop" ]; then
    xdg-mime default firefox-esr.desktop text/html
    echo "[ INFO - firefox ok - $( date )]"
fi

echo "[ INFO - fim da execução - $( date ) ]"
