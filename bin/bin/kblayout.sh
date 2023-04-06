#/bin/bash

CUR_LAYOUT=$(setxkbmap -print -verbose 10 | grep layout | cut -d ":" -f2 | tr -d '[:blank:]')

case $CUR_LAYOUT in
  us) 
    MSG="it"
    setxkbmap -layout it;
  ;;
  it) 
    MSG="us"
    setxkbmap -layout us;
  ;;
  *) 
    MSG="Error switching layout!";
  ;;
esac

notify-send --icon=keyboard --urgency=normal -t 3000 "keyboard layout: ${MSG}"
