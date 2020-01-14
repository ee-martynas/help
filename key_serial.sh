#!/bin/bash

read key

cipher="cbdefghijklnrtuv"
hex="0123456789abcdef"

function decode {
	index=$(expr index "$cipher" $1 )
	hex_key+=${hex:$(($index-1)):1}
}


for i in {0..11}
do
	decode ${key:$i:1}
done

echo $(( 16#$hex_key ))
