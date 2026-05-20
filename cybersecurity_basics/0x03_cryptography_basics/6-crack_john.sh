#!/bin/bash
john --show --format=Raw-SHA256 "$1" | cut -d: -f2 > 6-password.txt
