plugins=(docker docker-compose fasd tmux zsh-autosuggestions vi-mode)

# ignore hosts file autocompletion
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//,/ }
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

export EDITOR=nvim
export VISUAL=nvim

export ZSH="$HOME/.oh-my-zsh"

export BAT_THEME="TwoDark"

ZSH_THEME="robbyrussell"

[ -f $ZSH/oh-my-zsh.sh ] && source $ZSH/oh-my-zsh.sh

# Custom configs import
CUSTOM_DIR="$(dirname $0)"
[ -f $CUSTOM_DIR/aliases.sh ] && source $CUSTOM_DIR/aliases.sh
[ -f $CUSTOM_DIR/functions.sh ] && source $CUSTOM_DIR/functions.sh

### Other ###

# use fd or fdfind depending on what exists (ubuntu uses fdfind instead of fd)
FD_OPTIONS='--follow --hidden --exclude .git --exclude ".Trash*"'
command -v fdfind >/dev/null && export FZF_DEFAULT_COMMAND="fdfind $FD_OPTIONS"
command -v fdfind >/dev/null && export FZF_ALT_C_COMMAND="fdfind --type d $FD_OPTIONS"
command -v fdfind >/dev/null && export FZF_CTRL_T_COMMAND="fdfind --type f --type d $FD_OPTIONS"
command -v fd >/dev/null && export FZF_DEFAULT_COMMAND=scm_bre"fd $FD_OPTIONS"
command -v fd >/dev/null && export FZF_ALT_C_COMMAND="fd --type d $FD_OPTIONS"
command -v fd >/dev/null && export FZF_CTRL_T_COMMAND="fd --type f --type d $FD_OPTIONS"

# Fzf previews
export FZF_DEFAULT_OPTS="
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --preview-window 'right:50%:hidden:wrap'
  --preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"

_fzf_compgen_path() {
  command -v fd >/dev/null && fd --follow --hidden --exclude .git --exclude ".Trash*" . "$1"
  command -v fdfind >/dev/null && fd --follow --hidden --exclude .git --exclude ".Trash*" . "$1"

}
_fzf_compgen_dir() {
  command -v fd >/dev/null && fd --type d --follow --hidden --exclude .git --exclude ".Trash*" . "$1"
  command -v fdfind >/dev/null && fdfind --type d --follow --hidden --exclude .git --exclude ".Trash*" . "$1"
}
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fixing tmux colors in some cases
alias tmux="TERM=screen-256color-bce tmux"

# zsh syntax highlighting
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f $HOME/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source $HOME/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[ -f $HOME/.zsh-plugins/fzf-tab/fzf-tab.plugin.zsh ] && source $HOME/.zsh-plugins/fzf-tab/fzf-tab.plugin.zsh

# scm_breeze
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

# node version manager
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Aichat
[ -s "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_integration.zsh" ] && source "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_integration.zsh"
[ -s "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_autocomplete.zsh" ] && source "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_autocomplete.zsh"

# enable vi mode
bindkey -v
# vi mode plugin settings
VI_MODE_SET_CURSOR=true
# fixing Alt+. in zsh vi mode
bindkey -M viins '\e.' insert-last-word
bindkey '^[^?' backward-kill-word

[ -s "/home/user/.scm_breeze/scm_breeze.sh" ] && source "/home/user/.scm_breeze/scm_breeze.sh"

export PATH=/home/user/.local/bin:$PATH
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# source /usr/share/fzf/key-bindings.zsh
# source /usr/share/fzf/completion.zsh
# source <(fzf --zsh)

# Attach to zellij session (if not already running, and only in a desired terminal emulator)
# USER_TERMINAL_EMULATOR='alacritty'
# CURRENT_TERMINAL_EMULATOR=$(basename "/"$(ps -o cmd -f -p $(cat /proc/$(echo $$)/stat | cut -d \  -f 4) | tail -1 | sed 's/ .*$//'))
# if [[ $CURRENT_TERMINAL_EMULATOR = $USER_TERMINAL_EMULATOR ]]; then
#   zellij a
# fi

# eval "$(navi widget zsh)" # setup navi widget (ctrl + g). https://github.com/denisidoro/navi
# eval "$(fasd --init auto)"
eval "$(starship init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(zoxide init zsh)"
