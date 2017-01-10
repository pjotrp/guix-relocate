#! /bin/sh
# 
# Compile with -g -debug and run gdb:
#
#   gdb --args ./installer/bin/guix-relocate -v -d  --prefix /gnu/tmp/sambamba.new --origin `pwd` ./gnu/store/9fz1bak63p51ywrgjrcy0xha7hd7g43y-pkg-config-0.29/bin/pkg-config
#
# Useful commands
#
# list
# break #
# n(ext)
# s(kip)
# c(ont)
# r(un)
# bt
#
rdmd --force -g -debug -ofguix-relocate --build-only src/main.d $* 
