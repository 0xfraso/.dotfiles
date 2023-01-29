source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

export FZF_DEFAULT_COMMAND="fd --hidden . $HOME"
# export FZF_DEFAULT_OPTS="--layout=reverse --padding=1 --color=dark"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d --hidden . $HOME"

#export FZF_DEFAULT_OPTS='
#    --color=fg:#f2f4f8,bg:#161616,hl:#bd93f9
#    --color=fg+:#f2f4f8,bg+:#484848,hl+:#bd93f9
#    --color=info:#2dc7c4,prompt:#25be6a,pointer:#ee5396
#    --color=marker:#ee5396,spinner:#ffb86c,header:#484848
#    --border'

export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
    --border"

# file edit with default $EDITOR
function fe() {
  IFS=$'\n' files=($(fd --hidden . $HOME -t f | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# find file in cwd
function ff() {
  IFS=$'\n' files=($(fd --hidden . -t f | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# find and extract (.tgz)
function ft() {
	selected=$(find $HOME -type f -name "*.tgz" | fzf);
	if [[ ${selected} != "" ]]; then 
		tar xvzf $selected;
	else
		echo "please select a file to extract"
	fi
}

# directory browse with preview
function fb() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" | 
          fzf --prompt 'file browser > ' --multi --reverse --preview ' __cd_nxt="$(echo {})"; __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")"; echo $__cd_path; echo; ls -p --color=always "${__cd_path}"; ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}

# Install packages using yay (change to pacman/AUR helper of your choice)
function in() {
    yay -Slq | fzf -m -q "$1" -m --preview 'yay -Si {1}'| xargs -ro yay -S
}

# Remove installed packages (change to pacman/AUR helper of your choice)
function re() {
    yay -Qq | fzf -q "$1" -m --preview 'yay -Qi {1}' | xargs -ro yay -Rns
}

# kill process
function fk() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}
