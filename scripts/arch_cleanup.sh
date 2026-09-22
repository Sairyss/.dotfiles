sudo paccache -rki

rm -rf ~/.cache/yay/*

sudo pacman -Rns $(pacman -Qtdq)

sudo journalctl --vacuum-time=2weeks

## rm -rf ~/.cache/*
