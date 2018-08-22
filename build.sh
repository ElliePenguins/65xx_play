#!/bin/bash

./../cc65/bin/ca65 -t c64 -o objectFiles/$1.o src/$1.s
./../cc65/bin/ld65 -t c64 -o bin/$1 objectFiles/$1.o ../cc65/lib/c64.lib
