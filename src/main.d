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
  return tuple(from2,target2,rest);
}

void relocate_file(string fn,string outfn,in string[string] store_entries) {
  char[] buf = cast(char [])read(fn); // assume the file fits into RAM

  void patch(char[] b) {
    immutable b_short = take(b[0..$],128).to!string;  // assume base store path is shorter
    string path = split(b_short,"/")[0..4].join("/"); // rejoin first 3 sections of store path
    debug_info("Found @",b.ptr-buf.ptr,":\t\t",path);
    if (indexOf(path,"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-") != -1) {
      b[0] = '*'; // disabling any store reference
    }
    else {
      // In some cases the string is too long so we walk backwards for a match
      Tuple!(string,string) find_path_target(string path) {
        immutable target = store_entries.get(path,null);
        if (path == "" || path == "/gnu/store")
          return tuple(cast(string)null,cast(string)null);
        if (target)
          return tuple(target,path);
        else
          return find_path_target(path[0..$-1]);
      }
      immutable path_target = find_path_target(path);
      immutable target = path_target[0];
      immutable p = path_target[1];
      if (!target) {
        warning("Can not find target for <"~path~">");
        b[0] = '*'; // disable any store reference
      }
      else {
        debug_info("Replace with\t\t",target);
        assert(p.length == target.length, "Size mismatch between <"~p~"> and <"~target~">");
        foreach(int i, char c; target) {
          b[i] = c; // overwrite
        }
      }
    }
  }

  void finder(char[] b) {
    auto found = find(b, cast(char[])"/gnu/store/");
    if (found.empty)
      return;
    else {
      patch(found);
      return finder(found[10..$]);
    }
  }
  finder(buf);
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
    immutable fn = origin ~ "/" ~ args[1];
    if (prefix[$-1]!=dirSeparator[0]) // make sure prefix ends with a separator
      prefix = prefix ~ dirSeparator;
    assert(isDir(prefix));
    immutable path_fn_tuple = reduce_store_path(args[1],prefix);
    immutable outfn = path_fn_tuple[1]~"/"~path_fn_tuple[2];
    debug_info("File = ",fn,", Origin = ",origin,", Prefix = ",prefix,", Output = ",outfn);
    immutable store = origin ~ "/gnu/store";
    assert(isDir(store));
    // ---- harvest Guix hashes and translate to new prefix path with
    // hash at end so /gnu/store/hash-entry points to
    // $prefix/entry-hash with the exact same size
    string[string] store_entries;
    foreach(d; dirEntries(store,SpanMode.shallow)) {
      immutable target = reduce_store_path(d,prefix)[1];
      foreach (key, value ; store_entries) {
        if (target == value)
          error("Key conflict for "~target~". Try a shorter prefix.");
      }
      // assert(exists(target),"Directory already exists "~target);
      store_entries["/gnu/store/"~baseName(d)] = target;
    }
    debug_info(store_entries);
    relocate_file(fn,outfn,store_entries);
  }
}

unittest {
  import std.process;
  messages.is_debug = true;
  messages.is_verbose = true;
  string[] guix_list = ["/gnu/store/xqpfv050si2smd32lk2mvnjhmgb4crs6-bash-4.3.42/bin/bash",
                        "/gnu/store/apx87qb8g3f6x0gbx555qpnfm1wkdv4v-coreutils-8.25"];
  string[string] store_entries;
  foreach(string p; guix_list) {
    immutable t = reduce_store_path(p,"/home/user/opt/my_tests/");
    info(t);
    store_entries[t[0]] = t[1];
  }
  debug_info(store_entries);
  relocate_file("test/data/paths.txt","test/output/paths.txt",store_entries);
  auto pid = spawnShell("diff test/output/paths.txt.ref test/output/paths.txt");
  immutable exitcode = wait(pid);
  if (exitcode != 0) exit(exitcode); // make sure to exit test with exit code
}
