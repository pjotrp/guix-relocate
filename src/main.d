// Guix binary relocate
//
// Pjotr Prins (c) 2017

import std.stdio, std.getopt, std.file, std.path, std.array, std.range, std.conv, std.string, std.typecons;
import core.sys.posix.stdlib;
import std.algorithm.searching;
import messages;

auto reduce_store_path(string fn, string prefix) {
  debug_info("Reduce store path "~fn);
  auto sub_paths = fn.split("/");
  auto idx = countUntil(sub_paths,"gnu");
  assert(sub_paths[idx+1] == "store", fn~" is not a /gnu/store path");
  immutable from = sub_paths[idx+2];
  immutable rest = sub_paths[idx+3..$].join("/");
  debug_info("Rest is "~rest);
  immutable split_path = split(from,"-");
  assert(split_path.length >= 3,"Guix path "~from~" does not look complete");
  immutable target = prefix ~ split_path[1..$].join("-") ~ "-" ~ split_path[0] ~ "padpadpadpadpadpadpadpadpadpadpadpadpad";
  immutable from2 = "/gnu/store/"~from;
  immutable target2 = to!string(target.take(from2.length));
  if (target2.length != from2.length)
    error("Paths not equally sized for "~target2); // not supposed to happen
  assert(indexOf(target2,"/gnu/store")==-1,"/gnu/store is not allowed in the target "~target2);
  info(from2," -> ",target2);
  return tuple(target2,rest);
}

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

Relocate a file replacing Guix finger prints using a fast search
algorithm and copy the file in the process.

Usage:

  guix-relocate [-v] [-d] [--origin path] --prefix path FILE

FILE is the file to be relocated relative to the orgin store path. Note that
this path is normally not pointing to a real Guix store, but to an unpacked
tar ball containing ./gnu/store/path(s).
",help.options);
  }
  else {
    info("guix-relocate by Pjotr Prins (C) 2017 pjotr.prins@thebird.nl");
    debug_info(args);
    if (args.length != 2) error("Wrong number of arguments");
    auto fn = origin ~ "/" ~ args[1];
    char[] buf = cast(char [])read(fn); // assume the file fits into RAM
    if (prefix[$-1]!=dirSeparator[0]) // make sure prefix ends with a separator
      prefix = prefix ~ dirSeparator;
    assert(isDir(prefix));
    immutable res = reduce_store_path(args[1],prefix);
    auto outfn = res[0]~"/"~res[1];
    debug_info("File = ",fn,", Size = ",buf.length,", Origin = ",origin,", Prefix = ",prefix,", Output = ",outfn);
    auto store = origin ~ "/gnu/store";
    assert(isDir(store));
    // ---- harvest Guix hashes and translate to new prefix path with
    // hash at end so /gnu/store/hash-entry points to
    // $prefix/entry-hash with the exact same size
    string[string] store_entry;
    foreach(d; dirEntries(store,SpanMode.shallow)) {
      auto target = reduce_store_path(d,prefix)[0];
      foreach (key, value ; store_entry) {
        if (target == value)
          error("Key conflict for "~target~". Try a shorter prefix.");
      }
      // assert(exists(target),"Directory already exists "~target);
      store_entry["/gnu/store/"~baseName(d)] = target;
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
      pos = indexOf(buf,"/gnu/store"); // should replace with Boyer Moore
    }
    // mkdirRecurse(dirName(outfn)); <- for now we assume it exists
    debug_info("Writing "~outfn);
    std.file.write(outfn,buf);
  }
}
