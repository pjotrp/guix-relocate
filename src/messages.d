module messages;

import std.stdio;

bool debug_info;

void set_debug(bool deb)
{
  debug_info = deb;
}

void deb(string[] s)
{
    if (debug_info)
      stderr.writeln(s);
}
