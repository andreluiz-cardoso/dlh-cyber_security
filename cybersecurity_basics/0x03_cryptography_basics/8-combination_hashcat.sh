#!/bin/bash
john --format=Raw-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt "$1"
john --show --format=Raw-SHA256 "$1" | grep "^?:" | cut -d: -f2 > 6-password.txt
