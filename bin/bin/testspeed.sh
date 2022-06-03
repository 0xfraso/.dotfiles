#!/bin/bash 

if [[ $# < 2 ]]; then
	echo "invalid arguments"
	echo "Usage: $(basename $0) [script name] [# of tests]"
	exit 1
fi

SCRIPT="$1"
N="$2"

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
	echo "Usage: $(basename $0) [script name] [# of tests]"
	exit 0
fi 
 

echo "Testing.."
time(for i in $(eval echo "{1..$N}"); do
./"$SCRIPT" &>/dev/null
done)
