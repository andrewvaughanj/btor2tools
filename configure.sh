#!/bin/sh

asan=no
check=no
debug=no
gcov=no
gprof=no
flto=no
shared=no
static=no
arch=unknown

#--------------------------------------------------------------------------#

die () {
  echo "*** configure.sh: $*" 1>&2
  exit 1
}

usage () {
cat <<EOF
usage: ./configure.sh [<option> ...]

where <option> is one of the following:

  -O                optimized compilation (default)
  -flto             enable link time optimization
  -static           static compilation
  -g                compile with debugging support
  -c                check assertions even in optimized compilation
  -m{32,64}         force 32-bit or 64-bit compilation
  -shared           shared library
  -asan             compile with -fsanitize=address -fsanitize-recover=address
  -gcov             compile with -fprofile-arcs -ftest-coverage
  -gprof            compile with -pg

You might also want to use the environment variables
CC and CXX to specify the used C and C++ compiler, as in

  CC=gcc-4.4 CXX=g++-4.4 ./configure.sh

which forces to use 'gcc-4.4' and 'g++-4.4'.
EOF
  exit 0
}

#--------------------------------------------------------------------------#

while [ $# -gt 0 ]
do
  case $1 in
    -g) debug=yes;;
    -O) debug=no;;
    -c) check=yes;;
    -m32|--m32) arch=32;;
    -m64|--m64) arch=64;;
    -flto) flto=yes;;
    -shared) shared=yes;;
    -static) static=yes;;
    -asan) asan=yes;;
    -gcov) gcov=yes;;
    -gprof) gprof=yes;;
    -h|-help|--help) usage;;
    -*) die "invalid option '$1' (try '-h')";;
  esac
  shift
done

#--------------------------------------------------------------------------#

[ X"$CC" = X ] && CC=gcc

if [ X"$CFLAGS" = X ]
then
  [ $debug = unknown ] && debug=no
  CFLAGS="-W -Wall -Wextra -Wredundant-decls"
  [ $arch = 32 ] && CFLAGS="$CFLAGS -m32"
  [ $arch = 64 ] && CFLAGS="$CFLAGS -m64"
  [ $static = yes ] && CFLAGS="$CFLAGS -static"
  [ $shared = yes ] && CFLAGS="$CFLAGS -fPIC"
  if [ $debug = yes ]
  then
    CFLAGS="$CFLAGS -g3 -ggdb"
  else
    CFLAGS="$CFLAGS -O3"
    [ $check = no ] && CFLAGS="$CFLAGS -DNDEBUG"
    [ $flto = yes ] && CFLAGS="$CFLAGS -flto"
  fi
elif [ $debug = yes ]
then
  die "CFLAGS environment variable defined and '-g' used"
elif [ $debug = no ]
then
  die "CFLAGS environment variable defined and '-O' used"
fi
[ $asan = yes ] && CFLAGS="$CFLAGS -fsanitize=address -fsanitize-recover=address"
[ $gcov = yes ] && CFLAGS="$CFLAGS -fprofile-arcs -ftest-coverage"
[ $gprof = yes ] && CFLAGS="$CFLAGS -pg"
echo "$CC $CFLAGS"
rm -f makefile
BINDIR="bin"
BUILDIR="build"
SRCDIR="src"
TARGETS="$BINDIR/catbtor $BINDIR/btorsim"
[ $shared = yes ] && TARGETS="$TARGETS $BUILDIR/libbtor2parser.so"
sed \
  -e "s,@CC@,$CC," \
  -e "s,@CFLAGS@,$CFLAGS," \
  -e "s,@BUILDIR@,$BUILDIR," \
  -e "s,@BINDIR@,$BINDIR," \
  -e "s,@SRCDIR@,$SRCDIR," \
  -e "s,@TARGETS@,$TARGETS," \
  makefile.in > makefile
echo "makefile generated"
