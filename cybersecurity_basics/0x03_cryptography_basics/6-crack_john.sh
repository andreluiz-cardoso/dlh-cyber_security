#!/bin/bash
john --show --format=Raw-SHA256 "$1" | grep -Eo '[a-f0-9]+:.+' | cut -d: -f2 > 6-password.txt
