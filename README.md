# Simple relocator for binary Guix packages

Simple fast file relocator, copying the file in the process.

The current version of guix-relocate takes a list of known finger
prints and replaces them with an equally sized path. This brute force
method should work across all known file formats.

The idea is that the /gnu/store/hash-package-version/ path is
cannibalized for the target directory.
