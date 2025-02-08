IgnorePath '/' # ignore all for now to avoid some issues
IgnorePath '/boot/*'
IgnorePath '/var/tmp/*'
IgnorePath '/tmp/*'
IgnorePath '/mnt/*'
IgnorePath '/dev/*'
IgnorePath '/sys/*'
IgnorePath '/var/log/*'
# IgnorePath '/var/lib/plex/*'
# IgnorePath '/usr/lib/udev/*'
# IgnorePath '/usr/lib/modules/*'
# IgnorePath '/var/lib/docker/*'
# IgnorePath '/var/lib/mlocate/*'
IgnorePath '/usr/share/mime/*'
IgnorePath '/usr/share/icons/*'
IgnorePath '/usr/share/themes/*'
IgnorePath '/usr/lib32/*'
IgnorePath '/usr/lib64/*'
IgnorePath '/etc/grub.d/*'
IgnorePath '/etc/openvpn/*'
IgnorePath '/etc/systemd/*'
IgnorePath '/etc/fonts/*'
IgnorePath '/etc/X11/*'
IgnorePath '/etc/sudoers'
IgnorePath '/etc/xml/*'
IgnorePath '/etc/default/*'
IgnorePath '/etc/sudoers.d/*'
IgnorePath '/etc/nsswitch.conf'
IgnorePath '/etc/sddm.conf'
IgnorePath '*/*.lock'
IgnorePath '/etc/os-release'

# docker
IgnorePath '/etc/docker/*'

# Time
IgnorePath '/etc/localtime'
IgnorePath '/etc/timezone'
IgnorePath '/etc/adjtime'

# Pacman
IgnorePath '/etc/pacman.d/*'
IgnorePath '/etc/pacman.conf'
IgnorePath '/etc/pacman.conf.pacnew'
IgnorePath '/etc/pamac.conf'

# Network
IgnorePath '/etc/NetworkManager/*'

# Certificate databases
IgnorePath '/etc/ca-certificates/extracted/*'
IgnorePath '/etc/ssl/certs/*'
IgnorePath '/etc/pacman.d/gnupg/*'

# Cache and generated files
IgnorePath '/var/cache/*'
IgnorePath '/etc/*.cache'
IgnorePath '/etc/*.gen'

# Password files
IgnorePath '/etc/*shadow*'
IgnorePath '/usr/share/*'
IgnorePath '/etc/passwd'

# Mount files
IgnorePath '*/.updated'
IgnorePath '/lost+found'
IgnorePath '/lost+found/*'
IgnorePath '*/lost+found/*'

# Opt packages (check that they don't include config)
IgnorePath '/opt/*'

# Binary libraries
IgnorePath '/usr/lib/*'

# Local binaries
IgnorePath '/usr/local/include/*'
IgnorePath '/usr/local/lib/*'
IgnorePath '/usr/local/share/applications/mimeinfo.cache'

# Var databases, logs, swap and temp files
IgnorePath '/var/db/sudo'
IgnorePath '/var/lib/*'
IgnorePath '/var/log/*'
IgnorePath '/var/swap*'
IgnorePath '/var/tmp/*'
