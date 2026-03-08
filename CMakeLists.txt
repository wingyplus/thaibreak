cmake_minimum_required(VERSION 3.14)
project(thaibreak C CXX)

cmake_policy(SET CMP0135 NEW)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(ExternalProject)

# Paths passed in from the Makefile
set(FINE_INCLUDE_DIR "" CACHE PATH "Path to fine C++ headers")
set(ERL_INCLUDE_DIR  "" CACHE PATH "Path to Erlang erts include directory")
set(PRIV_DIR         "" CACHE PATH "Output directory for the NIF .so")

if(NOT FINE_INCLUDE_DIR OR NOT ERL_INCLUDE_DIR OR NOT PRIV_DIR)
  message(FATAL_ERROR
    "Required variables not set. Pass:\n"
    "  -DFINE_INCLUDE_DIR=...\n"
    "  -DERL_INCLUDE_DIR=...\n"
    "  -DPRIV_DIR=...\n"
  )
endif()

# ---- Dependencies install prefix ----
set(DEPS_PREFIX ${CMAKE_BINARY_DIR}/vendor)

# Touch autotools-generated files so make doesn't try to regenerate them
# (avoids "Makefile.in is older than Makefile.am" issues in out-of-source builds)
set(TOUCH_AUTOTOOLS
  find <SOURCE_DIR> -name "Makefile.in" -o -name "configure" -o -name "aclocal.m4"
    | xargs touch
)

# ---- libdatrie (required by libthai) ----
ExternalProject_Add(libdatrie_ext
  URL      https://github.com/tlwg/libdatrie/releases/download/v0.2.13/libdatrie-0.2.13.tar.xz
  URL_HASH SHA256=12231bb2be2581a7f0fb9904092d24b0ed2a271a16835071ed97bed65267f4be
  PATCH_COMMAND
    find <SOURCE_DIR> \( -name "Makefile.in" -o -name "configure" -o -name "aclocal.m4" \)
         -exec touch {} +
  CONFIGURE_COMMAND
    <SOURCE_DIR>/configure
      --prefix=${DEPS_PREFIX}
      --enable-static
      --disable-shared
      --disable-dependency-tracking
      CFLAGS=-fPIC
  BUILD_COMMAND     make -j4
  INSTALL_COMMAND   make install
  BUILD_IN_SOURCE   FALSE
)

# ---- libthai ----
ExternalProject_Add(libthai_ext
  DEPENDS  libdatrie_ext
  URL      https://github.com/tlwg/libthai/releases/download/v0.1.30/libthai-0.1.30.tar.xz
  URL_HASH SHA256=ddba8b53dfe584c3253766030218a88825488a51a7deef041d096e715af64bdd
  PATCH_COMMAND
    find <SOURCE_DIR> \( -name "Makefile.in" -o -name "configure" -o -name "aclocal.m4" \)
         -exec touch {} +
  CONFIGURE_COMMAND
    <SOURCE_DIR>/configure
      --prefix=${DEPS_PREFIX}
      --enable-static
      --disable-shared
      --disable-dependency-tracking
      CFLAGS=-fPIC
      CPPFLAGS=-I${DEPS_PREFIX}/include
      LDFLAGS=-L${DEPS_PREFIX}/lib
      PKG_CONFIG_PATH=${DEPS_PREFIX}/lib/pkgconfig
      PATH=${DEPS_PREFIX}/bin:$ENV{PATH}
  BUILD_COMMAND     ${CMAKE_COMMAND} -E env PATH=${DEPS_PREFIX}/bin:$ENV{PATH} make -j4
  INSTALL_COMMAND   ${CMAKE_COMMAND} -E env PATH=${DEPS_PREFIX}/bin:$ENV{PATH} make install
  BUILD_IN_SOURCE   FALSE
)

# ---- NIF shared library ----
add_library(thaibreak SHARED c_src/thaibreak.cpp)

add_dependencies(thaibreak libthai_ext)

target_include_directories(thaibreak PRIVATE
  ${FINE_INCLUDE_DIR}
  ${ERL_INCLUDE_DIR}
  ${DEPS_PREFIX}/include
)

target_compile_options(thaibreak PRIVATE
  -fvisibility=hidden
  -fPIC
  -O2
)

# Link against the static libraries we just built, so the resulting .so
# has no runtime dependency on system libthai / libdatrie.
target_link_libraries(thaibreak PRIVATE
  ${DEPS_PREFIX}/lib/libthai.a
  ${DEPS_PREFIX}/lib/libdatrie.a
)

set_target_properties(thaibreak PROPERTIES
  OUTPUT_NAME               thaibreak
  PREFIX                    ""
  SUFFIX                    ".so"
  LIBRARY_OUTPUT_DIRECTORY  ${PRIV_DIR}
)
