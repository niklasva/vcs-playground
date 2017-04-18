if [[ "$1" != "" ]]; then
    dasm src/$1.asm -Iinclude -lbin/$1.lst -sbin/$1.sym -obin/$1.bin -f3 -v5
    stella bin/$1.bin &
    osascript -e 'tell application "Stella" to activate'
else
    echo "Sorry"
fi
