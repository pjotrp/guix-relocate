# Simple relocator for binary Guix packages

Simple fast file relocator, copying the file in the process.

The current version of guix-relocate takes a list of known
fingerprints and replaces them with an equally sized path. This brute
force method should work across all known file formats as long
as the path is stored as a simple char array.

The idea is that the /gnu/store/hash-package-version/ path is
cannibalized for the target directory. Losing the hash value is not a
problem since all installations are isolated in the target directory. Examples are:

Found @512:     /gnu/store/qv7bk62c22ms9i11dhfl71hnivyc82k2-glibc-2.22
Replace with    /gnu/tmp/hello/glibc-2.22-qv7bk62c22ms9i11dhfl71hnivyc

Notes: The current version reads a file into memory and throws an
exception when the file is too large (a problem on tiny systems only).
Speed can probably be improved with Boyer-Moore and threads.

Pjotr Prins
