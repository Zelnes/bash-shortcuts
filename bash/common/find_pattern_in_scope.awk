# This script will look for a given pattern into the given files.
# It will then gives the file:line where the pattern is found
# It will also give the scope where the pattern was found
# For a C/C++ file, the scope is [{}]
# It is possible to specify another scope by specifying :
#   scopeBegin  = pattern
#   scopeEnd = pattern

BEGIN {
  if (!length(pat)) {
    usage()
    exit 1
  }
  list_files()
  inScope = 0;
  stAreafirstLine = 0;
  if (!length(scopeBegin))
    scopeBegin = "{"
  if (!length(scopeEnd))
    scopeEnd = "}"
}

function usage() {
  print "This script searches a pattern in files"
  print "It uses by default the command 'rg', or 'grep' if rg is not installed, to list"
  print "more efficiently which files to parse."
  print "You must give a pattern to look for via the variable 'pat'. Examples:"
  print "  pat=my_function    -> this will print scopes where my_function is called/defined"
  print "  pat='my pattern' -> this will print scopes where 'my pattern' is present"
  print "The pattern can also be a regex, take care to awk backslash's absorption"
  print
  print "You can also tells this script how to list the files"
  print "By default it uses 'rg -l', or 'grep -r -l'"
  print "You might give another command that lists more specically the files you want"
  print "If you put a '+' as the first character of the command, then the pattern will"
  print "be appended to the command. Examples:"
  print "  finder='find -name Makefile'"
  print "  finder='find -name \"*.[ch]\"'"
  print "  finder='+grep --include=\"*.[ch]\"'"
  print "Warning: This command must output a complete path to the files"
  print
  print "By default the script looks for scopes that are delimited by '{' '}'"
  print "You can still change it. Examples:"
  print "  scopeBegin=\"^#if\" scopeEnd=\"^#endif\" -> will look into preprocessor if where 'pat' is defined"
  print "  scopeBegin=define scopeEnd=endef -> will look into Makefile defines where 'pat' is defined"
  print
  print "Example:"
  print "awk -v pat=main -f <this_file>"
  print "awk -v pat='rm -' -v scopeBegin='^if' -v scopeEnd='^endif' -v finder=\"find -name '*akefile' -o -name '*.mk'\" -f <this_file>"
}

# This function list all files that contains the pattern
# It uses the command 'rg' if available, and fall back to
# 'grep' if not
function list_files() {
  if (!length(finder)) {
    "{ which rg || { which grep && echo ' -r'; } } | tr -d '\n'; echo ' -l'" | getline finder
    finder = "+"finder
  }
  if (substr(finder, 1, 1) == "+") {
    finder = substr(finder, 2, length(finder)) " '" pat "'"
  }
  printf("Using \"%s\" to find files\n", finder, pat)
  while (finder | getline) {
    ARGV[ARGC++] = $0
  }
}

# This function saves and format the current line into the staged area
function saveLine() {
  stArea[idx++] = $0;
}

# This function prints the staged area
function print_array(i, s, f, len) {
  print "-----------------";
  len = length(FNR);
  for (i in stArea) {
    s = " "
    for (f in found)
      if (stAreafirstLine == found[f]) {
        s = "*"
        break;
      }
    printf("%s[%s:%"len"d]:%s\n", s, FILENAME, stAreafirstLine++, stArea[i]);
  }
}

# The left scope is found, increment
$0 ~ scopeBegin { inScope++; }

# The right scope is found, increment
$0 ~ scopeEnd { inScope--; }

# When we reach the end of the last scope
inScope == 0 {
  # If we found at least one match, print the scope
  if (idxF > 1) {
    # If the current line contains the scopeEnd save it, otherwise discard it
    if ($0 ~ scopeEnd)
      saveLine();
    print_array();
  }
  # In all cases, reset evrything
  delete stArea;
  stAreafirstLine = FNR;
  idx = 1;
  delete found;
  idxF = 1;
}

# Save each line
{
  saveLine();
}

# The pattern is found, say it !
$0 ~ pat {
  found[idxF++] = FNR;
}