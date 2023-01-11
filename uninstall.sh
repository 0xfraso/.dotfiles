#!/bin/bash

for folder in $(echo $STOW_FOLDERS | sed "s/,/ /g")
do 
  echo "unstow $folder"
  stow -D $folder
done

