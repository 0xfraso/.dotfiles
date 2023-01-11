#!/bin/bash

current=$(light)

echo $current

if (( $(echo "$current <= 25" | bc -l) )); then
		light -S 50
	elif (( $(echo "($current > 25) && ($current <= 50)" | bc -l) )); then
		light -S 75
	elif (( $(echo "($current > 50) && ($current <= 75)" | bc -l) )); then
		light -S 100
	else
		light -S 25
fi
