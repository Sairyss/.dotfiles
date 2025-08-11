CONFIG_DIR="$(dirname $0)"

source $CONFIG_DIR/antidote/antidote.zsh

antidote load

export EDITOR=nvim
export VISUAL=nvim

export BAT_THEME="TwoDark"

source $CONFIG_DIR/functions.sh
source $CONFIG_DIR/aliases.sh

[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

# Atuin
zvm_after_init_commands+=(eval "$(atuin init zsh --disable-up-arrow)") # https://github.com/atuinsh/atuin/issues/977

# Aichat
source $CONFIG_DIR/plugins/aichat/aichat_autocomplete.sh
zvm_after_init_commands+=("source $CONFIG_DIR/plugins/aichat/aichat_integration.zsh")

# Bind up/down (and j/k in vim mode) to substring search history
zvm_after_init_commands+=("bindkey \"${terminfo[kcuu1]}\" history-substring-search-up")
zvm_after_init_commands+=("bindkey \"${terminfo[kcud1]}\" history-substring-search-down")
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
