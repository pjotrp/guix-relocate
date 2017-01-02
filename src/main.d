// Guix binary relocate
//
// Pjotr Prins (c) 2017

import std.stdio, std.getopt, std.file, std.path, std.array;
import messages;

void main(string[] args) {
  string origin = "./gnu/store", prefix;
  auto help = getopt(
    args,
    "origin", "origin location where ./gnu/store finger prints are harvested (default .)", &origin,
    "prefix", "prefix for destination", &prefix,
    "d", "debug information", &messages.is_debug,
    "v", "verbose", &messages.is_verbose,
    );
  if (help.helpWanted || prefix == null) {
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
    info("guix-relocate by Pjotr Prins (C) 2017 pjotr.prins@thebird.nl");
    debug_info(args);
    if (args.length != 2) error("Wrong number of arguments");
    auto fn = args[1];
    auto buf = read(fn); // assume the file fits into RAM
    debug_info("File = ",fn,", Size = ",buf.length,", Origin = ",origin,", Prefix = ",prefix);
    if (prefix[$-1]!=dirSeparator[0]) // make sure prefix ends with a separator
      prefix = prefix ~ dirSeparator;
    assert(isDir(prefix));
    auto store = origin ~ "/gnu/store";
    assert(isDir(store));
    // ---- harvest Guix hashes
    string[string] store_entry;
    foreach(d; dirEntries(store,SpanMode.shallow)) {
      auto from = baseName(d);
      auto list = split(from,"-");
      assert(list.length >= 3,"Guix path "~from~" does not look complete");
      auto target = prefix ~ list[1] ~ list[2];
      info(from," onto ",target);
      if (target.length > ("/gnu/store/"~from).length+1)
        error("Prefix size too large to patch store path for "~from);
      foreach (key, value ; store_entry) {
        if (target == value)
          error("Key conflict for "~from);
      }
      store_entry[from] = target;
    }
    writeln(store_entry);
  }
}
