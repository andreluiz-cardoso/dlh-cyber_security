#!/bin/bash
find "$1" -perm -4000 -ls 2>/dev/null
