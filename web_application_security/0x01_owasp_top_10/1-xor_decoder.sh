#!/bin/bash
python3 -c "
import base64, sys
data = base64.b64decode(sys.argv[1].replace('{xor}', ''))
print(''.join(chr(b ^ 0x5F) for b in data), end='')
" "$1"
