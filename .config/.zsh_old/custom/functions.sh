### Functions ###

# change dir and show contents
# cd() {
#   builtin cd $@ && l
# }

# Show contents of a directory when cd to it https://blog.meain.io/2019/automatically-ls-after-cd/
function list_all() {
  emulate -L zsh
  eza -alhF
}
if [[ ${chpwd_functions[(r)list_all]} != "list_all" ]];then
  chpwd_functions=(${chpwd_functions[@]} "list_all")
fi

# find and open file with a default app
op() {
  local file
  file="$(fzf | awk -F: '{print $1}')"

  if [[ -n $file ]]; then
    xdg-open $file &>/dev/null
  fi
}

# find and open file with vscode
vs() {
  local file
  file="$(fzf | awk -F: '{print $1}')"

  if [[ -n $file ]]; then
    code -n $file &>/dev/null
  fi
}

# archive extraction
# usage: ex <file>
ex() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar x $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *.deb) ar x $1 ;;
    *.tar.xz) tar xf $1 ;;
    *.tar.zst) unzstd $1 ;;
    *) echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
