// Guix relocate scans a file for Guix finger prints and replaces them
// with a new installation prefix, cutting the path to the exact same
// size.
//
// Pjotr Prins (c) 2017

import std.stdio, std.getopt, std.file, std.path, std.array, std.range, std.conv, std.string, std.typecons;
import core.sys.posix.stdlib;
import std.algorithm.searching;
import messages;

auto reduce_store_path(string fn, string prefix) {
  debug_info("Reduce store path "~fn);
  immutable sub_paths = fn.split("/");
  auto sub_paths_rev = sub_paths.dup.reverse;
  immutable idxrev = countUntil(sub_paths_rev,"gnu");
  assert(idxrev != -1, "This should not happen");
  immutable idx = sub_paths.length - idxrev - 1;
  writeln(sub_paths_rev);
  writeln(idx,sub_paths);
  assert(sub_paths[idx+1] == "store", fn~" is not a /gnu/store path");
  immutable from = sub_paths[idx+2];
  immutable rest = sub_paths[idx+3..$].join("/");
  debug_info("Rest is "~rest);
  immutable split_path = split(from,"-");
  assert(split_path.length >= 2,"Guix path "~from~" does not look complete");
  immutable target = prefix ~ split_path[1..$].join("-") ~ "-" ~ split_path[0] ~ "padpadpadpadpadpadpadpadpadpadpadpadpad";
  immutable from2 = "/gnu/store/"~from;
  immutable target2 = to!string(target.take(from2.length));
  if (target2.length != from2.length)
    error("Paths not equally sized for "~target2); // not supposed to happen
  assert(indexOf(target2,"/gnu/store")==-1,"/gnu/store is not allowed in the target "~target2);
  info(from2," -> ",target2);
  return tuple(target2,rest);
}

void patch_file(string fn,string outfn,in string[string] store_entries) {
  char[] buf = cast(char [])read(fn); // assume the file fits into RAM
  immutable buf_sliced = cast(string)buf;
  auto pos = indexOf(buf_sliced,"/gnu/store/");
  while(pos != -1) {
    immutable b = buf_sliced[pos..$];
    immutable path = split(b,"/")[0..4].join("/");
    debug_info("Found @",pos,":\t\t",path);
    if (indexOf(path,"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-") != -1) {
      buf[pos] = '*';
    }
    else {
      // In some cases the string is too long so we walk for a match
      string found;
      foreach(int i, char c; path) {
        auto p = path[0..$-i];
        found = store_entries.get(p,null);
        if (found) break;
      }
      immutable target = found;
      assert(target,"Can not find target for <"~path~">");
      debug_info("Replace with\t\t",target);
      foreach(int i, char c; target) {
        buf[pos+i] = c;
      }
    }
    pos = indexOf(buf,"/gnu/store/"); // may be replaced with Boyer Moore
  }
  // mkdirRecurse(dirName(outfn)); <- for now we assume it exists
  debug_info("Writing "~outfn);
  std.file.write(outfn,buf);
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
    if (prefix[$-1]!=dirSeparator[0]) // make sure prefix ends with a separator
      prefix = prefix ~ dirSeparator;
    assert(isDir(prefix));
    immutable path_fn_tuple = reduce_store_path(args[1],prefix);
    auto outfn = path_fn_tuple[0]~"/"~path_fn_tuple[1];
    debug_info("File = ",fn,", Origin = ",origin,", Prefix = ",prefix,", Output = ",outfn);
    auto store = origin ~ "/gnu/store";
    assert(isDir(store));
    // ---- harvest Guix hashes and translate to new prefix path with
    // hash at end so /gnu/store/hash-entry points to
    // $prefix/entry-hash with the exact same size
    string[string] store_entries;
    foreach(d; dirEntries(store,SpanMode.shallow)) {
      auto target = reduce_store_path(d,prefix)[0];
      foreach (key, value ; store_entries) {
        if (target == value)
          error("Key conflict for "~target~". Try a shorter prefix.");
      }
      // assert(exists(target),"Directory already exists "~target);
      store_entries["/gnu/store/"~baseName(d)] = target;
    }
    debug_info(store_entries);
    patch_file(fn,outfn,store_entries);
  }
}

unittest {
  string[string] store_entries;
  patch_file("test/data/paths.txt","test/output/paths.txt",store_entries);
}
