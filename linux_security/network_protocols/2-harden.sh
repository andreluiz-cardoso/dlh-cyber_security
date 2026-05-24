#!/bin/bash
find / -type d -perm -o+w -exec echo {} \; -exec chmod 755 {} \; 2>/dev/null
