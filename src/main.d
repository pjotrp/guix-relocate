// Guix binary relocate
//
// Pjotr Prins (c) 2017

import std.stdio, std.getopt, std.file, std.path, std.array, std.range, std.conv, std.string;
import core.sys.posix.stdlib;
import std.algorithm.searching;
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
    char[] buf = cast(char [])read(fn); // assume the file fits into RAM
    debug_info("File = ",fn,", Size = ",buf.length,", Origin = ",origin,", Prefix = ",prefix);
    if (prefix[$-1]!=dirSeparator[0]) // make sure prefix ends with a separator
      prefix = prefix ~ dirSeparator;
    assert(isDir(prefix));
    auto store = origin ~ "/gnu/store";
    assert(isDir(store));
    // ---- harvest Guix hashes and translate to new prefix
    string[string] store_entry;
    foreach(d; dirEntries(store,SpanMode.shallow)) {
      immutable from = baseName(d);
      immutable list = split(from,"-");
      assert(list.length >= 3,"Guix path "~from~" does not look complete");
      string name = list[1];
      string ver = list[2];
      immutable target = prefix ~ name ~ ver ~ "-" ~list[0] ~ "padpadpadpadpadpadpadpadpadpadpadpadpad";
      immutable from2 = "/gnu/store/"~from;
      immutable target2 = to!string(target.take(from2.length));
      info(from2," onto ",target2);
      if (target2.length != from2.length)
        error("Paths not equally sized for "~target2); // not supposed to happen
      assert(indexOf(target2,"/gnu/store")==-1,"/gnu/store is not allowed in the target "~target2);
      foreach (key, value ; store_entry) {
        if (target2 == value)
          error("Key conflict for "~target2~". Try a shorter prefix.");
      }
      assert(!exists(target),"Directory already exists "~target2);
      store_entry[from2] = target2;
    }
    debug_info(store_entry);
    // At this point we have the entries and we have a file in memory
    auto pos = indexOf(buf,"/gnu/store");
    while(pos != -1) {
      char[] p = buf[pos..$];
      immutable b = cast(string)buf[pos..pos+100];
      immutable path = split(b,"/")[0..4].join("/");
      debug_info("Found @",pos,":\t",path);
      immutable target = store_entry[path];
      debug_info("Replace with\t",target);
      foreach(int i, char c; target) {
        buf[pos+i] = c;
      }
      pos = indexOf(buf,"/gnu/store");
    }
    std.file.write("testit",buf);
  }
}
