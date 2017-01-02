module messages;

import std.stdio;
import core.vararg;

bool is_debug = false, is_verbose = false;

void info(T...)(T args)
{
  if (is_verbose)
    stderr.writeln(args);
}

void warning(T...)(T args)
{
  stderr.writeln(args);
}

void error(T...)(T args)
{
  stderr.writeln(args);
  throw new Exception(args);
}

void debug_info(T...)(T args)
{
  if (is_debug)
    stderr.writeln(args);
}
