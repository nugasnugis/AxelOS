#!/bin/bash
set -e

# 1. Structure Directories Layout Maps
mkdir -p config/auto config/hooks/normal config/package-lists config/includes.chroot/usr/bin config/includes.chroot/etc/skel/Desktop config/includes.chroot/lib/live/config config/includes.chroot/etc/sddm.conf.d config/includes.chroot/etc/sudoers.d config/includes.chroot/usr/share/images/desktop-base config/includes.chroot/etc/calamares/branding/axelos config/includes.chroot/etc/xdg config/includes.chroot/etc/skel/.config/autostart config/includes.chroot/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates

# 2. Base Configuration Override
echo '#!/bin/sh' > config/auto/config
echo 'lb config noauto --distribution testing --image-name "AxelOS" --archive-areas "main contrib non-free non-free-firmware" --bootappend-live "boot=live components live-config username=axlive hostname=axlive locales=en_US.UTF-8 splash plymouth.theme=axelos quiet"' > config/auto/config
chmod +x config/auto/config

# 3. Master Systems Branding Compiler Hook
cat << 'EOF' > config/hooks/normal/0500-force-identity.chroot
#!/bin/sh
set -e
echo "axlive" > /etc/hostname
sed -i 's/debian/axlive/g' /etc/hosts
mkdir -p /etc/live /etc/live/config.conf.d
echo -e 'LIVE_USERNAME="axlive"\nLIVE_HOSTNAME="axlive"' > /etc/live/config.conf
echo 'LIVE_USERNAME="axlive"' > /etc/live/config.conf.d/01-user.conf
echo 'LIVE_HOSTNAME="axlive"' > /etc/live/config.conf.d/02-host.conf
if ! id "axlive" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -p "" axlive || true
    usermod -aG sudo,audio,video,cdrom,dip,floppy,plugdev,netdev axlive || true
fi

# COMPLETE PURGE OF STOCK DEBIAN LAYOUT CONFIGURATIONS AND AUTOSTART GHOST WELCOME MODULES
apt-get purge -y plasma-welcome desktop-base live-installer live-installer-launcher calamares-settings-debian || true
rm -rf /usr/share/desktop-base /usr/share/doc/debian-faq /usr/share/xsessions/debian-*.desktop || true
rm -f /usr/share/applications/debian-*.desktop /usr/share/applications/*launcher*.desktop || true
rm -rf /usr/bin/plasma-welcome /usr/bin/welcome-center /usr/share/plasma/look-and-feel/org.kde.plasma.welcome || true
rm -f /etc/xdg/autostart/org.kde.plasma-welcome.desktop /etc/xdg/autostart/*welcome*.desktop || true

cat << 'LAUNCHER_EOF' > /usr/share/applications/calamares.desktop
[Desktop Entry]
Type=Application
Version=1.0
Name=Install AxelOS
GenericName=System Installer
Comment=Install AxelOS
Exec=sudo calamares
Icon=system-software-install
Terminal=false
Categories=System;
LAUNCHER_EOF

mkdir -p /usr/share/icons/hicolor/64x64/apps
cp -f /usr/share/icons/breeze-dark/apps/48/system-software-install.svg /usr/share/icons/hicolor/64x64/apps/kde-logo.png || true
EOF
chmod +x config/hooks/normal/0500-force-identity.chroot

# 4. User Workspace Icons Config
echo -e "[Desktop Entry]\nType=Application\nVersion=1.0\nName=Install AxelOS\nComment=Install the operating system to your hard drive\nExec=sudo calamares\nIcon=system-software-install\nTerminal=false\nCategories=System;" > config/includes.chroot/etc/skel/Desktop/install-axelos.desktop
chmod 755 config/includes.chroot/etc/skel/Desktop/install-axelos.desktop

# 5. Display Manager Configurations
echo -e "[Autologin]\nUser=axlive\nSession=plasma" > config/includes.chroot/etc/sddm.conf.d/autologin.conf
echo "axlive ALL=(ALL) NOPASSWD:ALL" > config/includes.chroot/etc/sudoers.d/axlive
chmod 440 config/includes.chroot/etc/sudoers.d/axlive

# 6. APT Lockout Hooks Config
echo -e '#!/bin/sh\nif [ -f /usr/bin/apt ] && [ ! -f /usr/bin/apt.real ]; then\nmv /usr/bin/apt /usr/bin/apt.real\necho "#!/bin/bash" > /usr/bin/apt\necho "echo -e \"\\033[1;31m[AxelOS Security Enforcer]\\033[0m Native '\''apt'\'' is restricted. Please use '\''axpm'\'' instead!\"" >> /usr/bin/apt\necho "exit 1" >> /usr/bin/apt\nchmod +x /usr/bin/apt; fi' > config/hooks/normal/0999-lockdown-apt.chroot
chmod +x config/hooks/normal/0999-lockdown-apt.chroot

echo -e "[Theme]\nName=breeze-dark\n[General]\nColorScheme=BreezeDark" > config/includes.chroot/etc/skel/.config/kdeglobals
echo -e "[Mouse]\nAccelerationProfile=-1\nCoordinateTransformationMatrix=1 0 0 0 1 0 0 0 1" > config/includes.chroot/etc/skel/.config/kcminputrc
echo -e "---\ncomponentName: axelos\nstrings:\n productName: AxelOS\n shortProductName: Axel\n version: 1.0 Testing\n shortVersion: 1.0\n versionedName: AxelOS 1.0 Testing\n shortVersionedName: AxelOS 1.0\n bootloaderEntryName: AxelOS\nimages:\n productLogo: \"/usr/share/icons/breeze-dark/apps/48/system-software-install.svg\"\n productIcon: \"/usr/share/icons/breeze-dark/apps/48/system-software-install.svg\"\nslideshow: []\nstyle:\n SIDEBAR_BACKGROUND: \"#1e1e2e\"\n SIDEBAR_TEXT: \"#cdd6f4\"\n SIDEBAR_TEXT_ACTIVE: \"#89b4fa\"" > config/includes.chroot/etc/calamares/branding/axelos/branding.desc

# 7. JavaScript Initialization Overlay
cat << 'JS_EOF' > config/includes.chroot/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates/axelos-layout.js
var desktops = desktops();
for (var i = 0; i < desktops.length; i++) {
    desktops[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktops[i].writeConfig("Image", "file:///usr/share/images/desktop-base/desktop-background.png");
}
JS_EOF

# 8. Custom Branded AxelOS Welcome Center Utility
cat << 'EOF' > config/includes.chroot/usr/bin/axelos-welcome-center
#!/bin/bash
sleep 4
kdialog --title "AxelOS Welcome Center" --msgbox "Thank you for downloading AxelOS!\n\nSystem is fully initialized and ready.\nSecure Liveboot Mode is operational.\nPackage manager 'axpm' is active."
EOF
chmod +x config/includes.chroot/usr/bin/axelos-welcome-center

cat << 'EOF' > config/includes.chroot/etc/skel/.config/autostart/axelos-welcome.desktop
[Desktop Entry]
Type=Application
Name=AxelOS Welcome Center
Exec=/usr/bin/axelos-welcome-center
Icon=system-help
Terminal=false
EOF

# 9. Non Free Drivers Mapping Hook
echo -e '#!/bin/sh\nsed -i "s/main/main contrib non-free non-free-firmware/g" /etc/apt/sources.list\n/usr/bin/apt.real update -qq || true\n/usr/bin/apt.real install -y firmware-linux-free firmware-linux-nonfree firmware-iwlwifi firmware-realtek firmware-brcm80211 -qq < /dev/null &' > config/includes.chroot/lib/live/config/2000-axelos-drivers
chmod +x config/includes.chroot/lib/live/config/2000-axelos-drivers

# 10. FIXED: Core System Package Selection String targeting qdbus-qt6
echo "linux-image-amd64 initramfs-tools sudo live-tools live-config-systemd user-setup graphicsmagick xserver-xorg-video-all xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-intel xserver-xorg-video-nouveau mesa-vulkan-drivers libgl1-mesa-dri pipewire pipewire-audio wireplumber bluez bluez-tools plasma-desktop plasma-workspace kde-standard konsole dolphin gamemode fastfetch btop calamares gparted squashfs-tools plymouth plymouth-themes network-manager network-manager-gnome plasma-nm firefox-esr hicolor-icon-theme kdialog qdbus-qt6" > config/package-lists/desktop.list.chroot

# 11. Core axpm Executable Logic 
cat << 'EOF' > config/includes.chroot/usr/bin/axpm
#!/bin/bash
echo -e "\033[1;34m[AxelOS Package Manager - axpm]\033[0m"
E="/usr/bin/apt.real"; [ ! -f "$E" ] && E="/usr/bin/apt"
if [ "$1" = "install" ]; then shift; sudo $E install -y "$@"; elif [ "$1" = "update" ]; then sudo $E update
elif [ "$1" = "setup-gaming-kernel" ]; then
    curl -s https://xanmod.org | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://xanmod.org repository main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
    sudo $E update && sudo $E install -y linux-xanmod-x64v3
elif [ "$1" = "install-suite" ]; then
    if [ "$2" = "hacking" ]; then sudo $E install -y nmap wireshark aircrack-ng john hydra burpsuite
    elif [ "$2" = "gaming" ]; then sudo $E install -y steam lutris gnutls-bin mesa-vulkan-drivers; fi
else echo "Usage: axpm [install|update|setup-gaming-kernel|install-suite]"; fi
EOF
chmod +x config/includes.chroot/usr/bin/axpm
