# Aliases
alias ls='eza --icons --group-directories-first'
alias vim='nvim'
alias nv="nvim"
alias zj="zellij"

# Link every skill in ~/.agents/skills into ~/.claude/skills
sync-skills() {
  local src="$HOME/.agents/skills" dst="$HOME/.claude/skills" src_path name link

  [[ -d "$src" ]] || { echo "sync-skills: $src not found" >&2; return 1; }
  mkdir -p "$dst"

  for src_path in "$src"/*; do
    [[ -e "$src_path" || -L "$src_path" ]] || continue
    name=${src_path:t}
    link="$dst/$name"

    if [[ -L "$link" ]]; then
      [[ "$link:A" == "$src_path:A" ]] && continue
      rm -- "$link"
    elif [[ -e "$link" ]]; then
      echo "sync-skills: skipped $name (real file/dir in $dst)" >&2
      continue
    fi

    ln -s "../../.agents/skills/$name" "$link" && echo "linked $name"
  done

  # Drop links whose ~/.agents/skills target was deleted
  for link in "$dst"/*; do
    [[ -L "$link" && ! -e "$link" ]] || continue
    target=$(readlink -- "$link")
    [[ "$target" == "../../.agents/skills/${link:t}" || "$target" == "$src"/* ]] || continue
    rm -- "$link" && echo "removed stale ${link:t}"
  done
}
