// Guix binary relocate
//
// Pjotr Prins (c) 2017

import std.stdio, std.getopt, std.file;
import messages;

void main(string[] args) {
  string origin,prefix;
  bool debug_info;
  auto help = getopt(
    args,
    "origin", "origin location where path finger prints are harvested (default ./gnu/store)", &origin,
    "prefix", "prefix for destination", &prefix,
    "d", "debug information", &debug_info,
    );
  set_debug(debug_info);
  if (help.helpWanted) {
    defaultGetoptPrinter("
guix-relocate by Pjotr Prins (c) 2017

Relocate a file replacing Guix finger prints using a fast Boyer-Moore
search algorithm and copy the file in the process.

Usage:

  guix-relocate [-v] [-d] [--origin path] --prefix path FILE

FILE is the file to be relocated relative to the orgin store path. Note that
this path is normally not pointing to a real Guix store.

",help.options);
  }
  else {
    deb(args);
    if (args.length != 2)
      throw new Exception("Wrong number of arguments");
    auto fn = args[1];
    auto buf = read(fn); // assume the file fits into RAM
    writeln("File = ",fn,", Size = ",buf.length);
  }
}
