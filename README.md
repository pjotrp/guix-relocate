# Simple relocator for binary Guix packages

Simple fast file relocator, copying the file in the process.

The current version of guix-relocate takes a list of known
fingerprints (actually directories in ./gnu/store) and replaces them
with an equally sized path. This brute force method should work across
all known file formats as long as the path is stored as a simple char
array. For Linux this should work as long as the path is identifiable
and unique.

The idea here is that the /gnu/store/hash-package-version/ path is
cannibalized for the target directory.

    Found @512:     /gnu/store/qv7bk62c22ms9i11dhfl71hnivyc82k2-glibc-2.22
    Replace with    /gnu/tmp/hello/glibc-2.22-qv7bk62c22ms9i11dhfl71hnivyc

Note that we inject the prefix (/gnu/tmp/hello) and revert the order
of the hash so glibc comes out front. Next we 'eat' the characters at
the end to get the exact same size.  Losing the hash value is not a
problem since all installations are isolated in the target
directory /gnu/tmp/hello/ anyway.

Notes: The current version reads a file into memory and throws an
exception when the file is too large (a problem on tiny systems only).

## AUTHOR

Copyright 2016-2017 Pjotr Prins <pjotr.guix@thebird.nl>

## LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## HOMEPAGE

Not yet available.
