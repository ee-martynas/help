#!/bin/bash

# Purpose of this script is to convert multiline text into csv format
# 'line1','line2','line3'
#
# Script exits when a blank line is inserted

echo "---"


exit_strategy() {
	echo "---"
	echo $input_lines
	exit
}

while read line
do
	[ -z "$line" ] && exit_strategy

	if [[ ! -z $input_lines ]]; then
		input_lines=$input_lines",'$line'"

	else
		input_lines="'$line'"
	fi

done

