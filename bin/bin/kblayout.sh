#/bin/bash

CUR_LAYOUT=$(setxkbmap -print -verbose 10 | grep layout | cut -d ":" -f2 | tr -d '[:blank:]')

case $CUR_LAYOUT in
  us) 
    notify-send --urgency=normal -t 3000 "switching to keyboard layout: it"
    setxkbmap -layout it;
  ;;
  it) 
    setxkbmap -layout us;
    notify-send --urgency=normal -t 3000 "switching to keyboard layout: us"
  ;;
  *) 
    echo "Error switching layout!";
  ;;
esac


