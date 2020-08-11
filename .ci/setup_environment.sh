#!/usr/bin/env bash

case $CC in
    gcc*)
        if [ $TRAVIS_OS_NAME = osx ]; then
            CC=gcc-9
            CXX=g++-9
            CCVERSION=gcc9
        else
            CCVERSION=gcc$($CC -dumpversion)
        fi
        ;;
    clang)
        CCVERSION=clang$(clang --version | fgrep version | \
                                sed "s/.*version \([0-9]*\.[0-9]*\).*/\1/" | \
                                cut -d "." -f 1)
        ;;
esac
declare -a DBG_ARGS
declare -a ADD_ARGS
declare -a COMMON_ARGS
DBG_ARGS=()
ADD_ARGS=()
COMMON_ARGS=()
if [ "$DEBUG" = "true" ]; then
    DBGN="-dbg"
    DBG_ARGS+=( --enable-debug )
    CXXFLAGS="-Og -g"
fi
if [ "$ASAN" = "true" ]; then
    ASN="-asan"
    ADD_CXXFLAGS="${ADD_CXXFLAGS} -fsanitize=address"
    LDFLAGS="-lasan"
fi
if [ "$BUILD_STATIC" = "true" ]; then
    STATIC="-static"
    ADD_ARGS+=( --static --with-lapack='-llapack -lblas -lgfortran -lquadmath -lm' )
fi
if [ "$CXX_FLAGS" != "" ]; then
    ADD_ARGS+=( CXXFLAGS=${CXXFLAGS} )
fi
if [ "$LD_FLAGS" != "" ]; then
    ADD_ARGS+=( LDFLAGS=${LDFLAGS} )
fi
COMMON_ARGS=( --no-prompt --verbosity ${VERBOSITY:-2} --tests main --enable-relocatable )
PLATFORM=$TRAVIS_OS_NAME${OSX:-}-x86_64-$CCVERSION
PROJECT_URL=https://github.com/$TRAVIS_REPO_SLUG
if [ $TRAVIS_OS_NAME = windows ]; then
    PATH=/C/tools/msys64/mingw64/bin:$PATH
fi
