if [[ "$1" != "" ]]; then
    dasm src/$1.s -Iinclude -lbin/$1.lst -sbin/$1.sym -obin/$1.bin -f3 -v5
else
    echo "Sorry"
fi
