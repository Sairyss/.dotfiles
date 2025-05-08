### ALIASES ###

# change dir aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'
alias ..5='cd ../../../../..'

# other aliases
alias l='eza -alhF'
alias ll='eza -lhF'
alias h='helix'
alias hs='history | grep -i'
alias mkdir='mkdir -pv'
alias rmdir='rmdir -v'
alias cp='cp -rvi'
alias rm='rm -vr'
alias mv='mv -v'
alias path='echo -e ${PATH//:/\\n}'
alias ff='find . -type f -iname'                  # find file
alias ftoday='find . -type f -daystart -mtime -1' # find today files
alias e2e='npm run test:e2e'
alias cht='/usr/local/bin/cht.sh'
alias cat='bat'
alias yank='yank-cli'
alias ch='cht.sh'
alias open="xdg-open"
alias logtmp="$HOME/.dotfiles/.config/.zsh/custom/scripts/logging/run_and_log_to_file.sh"
alias lnavtmp="$HOME/.dotfiles/.config/.zsh/custom/scripts/logging/lnav_log_temp_file.sh"
alias dev='logtmp npm run start:dev & lnavtmp && fg' # show logs in lnav
