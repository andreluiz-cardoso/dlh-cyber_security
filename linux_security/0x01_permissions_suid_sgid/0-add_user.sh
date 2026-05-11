#!/bin/bash
useradd -m "$1"
echo "$2" | passwd --stdin "$1"
