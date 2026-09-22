CONFIG_DIR="$(dirname $0)"

source $CONFIG_DIR/antidote/antidote.zsh

antidote load

export EDITOR=nvim
export VISUAL=nvim

export BAT_THEME="TwoDark"

source $CONFIG_DIR/functions.sh
source $CONFIG_DIR/aliases.sh

# do not enable SCM breeze within claude code sessions
if [[ -z "$CLAUDECODE" ]]; then
  [ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"
fi

# Atuin
zvm_after_init_commands+=(eval "$(atuin init zsh --disable-up-arrow)") # https://github.com/atuinsh/atuin/issues/977

# Aichat
source $CONFIG_DIR/plugins/aichat/aichat_autocomplete.sh
zvm_after_init_commands+=("source $CONFIG_DIR/plugins/aichat/aichat_integration.zsh")

# Bind up/down (and j/k in vim mode) to substring search history
zvm_after_init_commands+=("bindkey \"${terminfo[kcuu1]}\" history-substring-search-up")
zvm_after_init_commands+=("bindkey \"${terminfo[kcud1]}\" history-substring-search-down")
zvm_after_init_commands+=("bindkey '^[[A' history-substring-search-up")
zvm_after_init_commands+=("bindkey '^[[B' history-substring-search-down")
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Zellij shell integration: emit OSC 133 prompt markers so zellij can track
# prompt boundaries (ScrollToPreviousPrompt/NextPrompt, SelectCommandAtScrollPosition,
# CopyLastCommandOutput). zsh/bash don't emit these on their own (fish does).
# B must be emitted right where the command line starts (end of PROMPT).
if [[ -n "$ZELLIJ" ]]; then
  __zellij_osc133_precmd() {
    local exit_code=$?
    [[ -n "$__zellij_osc133_in_cmd" ]] && printf '\e]133;D;%d\a' "$exit_code"
    unset __zellij_osc133_in_cmd
    printf '\e]133;A\a'
  }
  __zellij_osc133_preexec() {
    printf '\e]133;C\a'
    __zellij_osc133_in_cmd=1
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __zellij_osc133_precmd
  add-zsh-hook preexec __zellij_osc133_preexec
  PROMPT="${PROMPT}"$'%{\e]133;B\a%}'
fi
