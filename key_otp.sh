#!/bin/bash

debug=$1

read -sp "Please touch your Yubikey:" -e otp
echo

function decode {
	index=$(expr index "$cipher" $1 )
	hex_key+=${hex:$(($index-1)):1}
}

function get_serial {
	key=$1
        cipher="cbdefghijklnrtuv"
        hex="0123456789abcdef"

	for i in {0..11}
	do
		decode ${key:$i:1}
	done

	echo $(( 16#$hex_key ))
}

serial=$(get_serial $otp)

id=$((1 + RANDOM % 10000))
nonce=($(sha1sum <<< $otp))

curl -XGET "https://api.yubico.com/wsapi/2.0/verify?id=$id&otp=$otp&nonce=$nonce"

if [ "$debug" ]; then
	echo "Serial: "$serial
	echo "Query ID: "$id
	echo "OTP: "$otp
	echo "Nonce: "$nonce
fi
