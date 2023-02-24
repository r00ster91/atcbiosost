#!/bin/sh

nasm -f bin -o bios-os.img main.s &&
qemu-system-x86_64 -drive file=bios-os.img,format=raw
