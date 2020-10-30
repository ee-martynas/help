#!/bin/bash

print_usage() {
  echo "Usage: ..."
  exit
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      shift
      print_usage
      ;;
    -a)
      shift
      account=$1
      shift
      ;;
    *)
      break
      ;;
  esac
done



#
#while getopts 'a:' flag; do
#  case "${flag}" in
#    a) account=$OPTARG ;;
#    *) print_usage
#       exit 1 ;;
#  esac
#done


echo $account