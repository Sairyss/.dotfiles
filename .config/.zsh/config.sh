source $HOME/.dotfiles/.config/.zsh/antidote/antidote.zsh

antidote load

export EDITOR=nvim
export VISUAL=nvim

export BAT_THEME="TwoDark"

source $HOME/.dotfiles/.config/.zsh/aliases.sh
source $HOME/.dotfiles/.config/.zsh/functions.sh

[ -f $CUSTOM_DIR/aliases.sh ] && source $CUSTOM_DIR/aliases.sh

[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

# Aichat
[ -s "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_integration.zsh" ] && source "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_integration.zsh"
[ -s "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_autocomplete.zsh" ] && source "$HOME/.dotfiles/.config/.zsh/custom/plugins/aichat_autocomplete.zsh"

# Atuin
zvm_after_init_commands+=(eval "$(atuin init zsh --disable-up-arrow)") # https://github.com/atuinsh/atuin/issues/977

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
