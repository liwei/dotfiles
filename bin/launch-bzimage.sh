#!/bin/bash

qemu-system-x86_64 -m 512 -kernel ./arch/x86/boot/bzImage -serial stdio -append "root=/dev/sda2 console=tty0 console=ttyS0" -snapshot /dev/sda
