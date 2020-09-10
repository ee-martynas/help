#!/usr/bin/python3

input_lines = ""

def exit_strategy():
    print("---")
    print(input_lines)
    exit(0)             # 0 - normal exit



while True:
    line = input()

    if not line:
        exit_strategy()

    if input_lines:
        input_lines += ",'"+line+"'"
    else:
        input_lines = "'"+line+"'"


