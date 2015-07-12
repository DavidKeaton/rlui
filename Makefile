######################################
# Lovingly stolen from Cataclysm-DDA #
######################################

# Platforms:
# Linux/Cygwin native
#   (don't need to do anything)
# Linux 64-bit
#   make NATIVE=linux64
# Linux 32-bit
#   make NATIVE=linux32
# Linux cross-compile to Win32
#   make CROSS=i686-pc-mingw32-
#   or make CROSS=i586-mingw32msvc-
#   or whichever prefix your crosscompiler uses
#      as long as its name contains mingw32
# Win32 (non-Cygwin)
#   Run: make NATIVE=win32
# OS X
#   Run: make NATIVE=osx

# Build types:
# Debug (no optimizations)
#  Default
# ccache (use compilation caches)
#  make CCACHE=1
# Release (turn on optimizations)
#  make RELEASE=1
# Install to system directories.
#  make install
# Enable lua support. Required only for full-fledged mods.
#  make LUA=1
# Use dynamic linking (requires system libraries).
#  make DYNAMIC_LINKING=1

# comment these to toggle them as one sees fit.
# DEBUG is best turned on if you plan to debug in gdb -- please do!
# PROFILE is for use with gprof or a similar program -- don't bother generally
# RELEASE is flags for release builds, we want to error on everything to make sure
# we don't check in code with new warnings, but we also have to disable some classes of warnings
# for now as we get rid of them.  In non-release builds we want to show all the warnings,
# even the ones we're allowing in release builds so they're visible to developers.
RELEASE_FLAGS = -Werror
WARNINGS = -Wall -Wextra
# Uncomment below to disable warnings
#WARNINGS = -w
ifeq ($(shell sh -c 'uname -o 2>/dev/null || echo not'),Cygwin)
  DEBUG = -g
else
  DEBUG = -g -D_GLIBCXX_DEBUG
endif
#PROFILE = -pg
#OTHERS = -O3
#DEFINES = -DNDEBUG

# Disable debug. Comment this out to get logging.
#DEFINES = -DENABLE_LOGGING

# Limit debug to level. Comment out all for all levels.
#DEFINES += -DDEBUG_INFO
#DEFINES += -DDEBUG_WARNING
#DEFINES += -DDEBUG_ERROR

VERSION = 0.1

PROJECT		= rlui
TARGET 		= lib$(PROJECT)
W32TARGET 	= lib$(PROJECT).dll

BINDIST_DIR = bindist
BUILD_DIR = $(CURDIR)
SRC_DIR = src
LUA_DIR = lua
LUASRC_DIR = src/lua
# if you have LUAJIT installed, try make LUA_BINARY=luajit for extra speed
LUA_BINARY = lua
#LOCALIZE = 1

# when preprocessor defines change, but the source doesn't
ODIR = obj
W32ODIR = objwin
DDIR = .deps

OS  = $(shell uname -s)

# if $(OS) contains 'BSD'
ifneq ($(findstring BSD,$(OS)),)
  BSD = 1
endif

# Expand at reference time to avoid recursive reference
OS_COMPILER := $(CXX)
# Appears that the default value of $LD is unsuitable on most systems
OS_LINKER := $(CXX)
ifdef CCACHE
  CXX = ccache $(CROSS)$(OS_COMPILER)
  LD  = ccache $(CROSS)$(OS_LINKER)
else
  CXX = $(CROSS)$(OS_COMPILER)
  LD  = $(CROSS)$(OS_LINKER)
endif
RC  = $(CROSS)windres

# We don't need scientific precision for our math functions, this lets them run much faster.
#CXXFLAGS += -ffast-math
# enable optimizations. slow to build
ifdef RELEASE
  ifeq ($(NATIVE), osx)
    CXXFLAGS += -O3
  else
    CXXFLAGS += -Os
    LDFLAGS += -s
  endif
  # OTHERS += -mmmx -m3dnow -msse -msse2 -msse3 -mfpmath=sse -mtune=native
  # Strip symbols, generates smaller executable.
  OTHERS += $(RELEASE_FLAGS)
  DEBUG =
  DEFINES += -DRELEASE
endif

ifdef CLANG
  ifeq ($(NATIVE), osx)
    OTHERS += -stdlib=libc++
  endif
  ifdef CCACHE
    CXX = CCACHE_CPP2=1 ccache $(CROSS)clang++
    LD  = CCACHE_CPP2=1 ccache $(CROSS)clang++
  else
    CXX = $(CROSS)clang++
    LD  = $(CROSS)clang++
  endif
  #WARNINGS = -Wall -Wextra -Wno-switch -Wno-sign-compare -Wno-missing-braces -Wno-type-limits -Wno-narrowing
  WARNINGS = -Wall -Wextra
endif

OTHERS += --std=c++11

CXXFLAGS += $(WARNINGS) $(DEBUG) $(PROFILE) $(OTHERS) -MMD

BINDIST_EXTRAS += README.md data doc
BINDIST    		= $(PROJECT)-$(VERSION).tar.gz
W32BINDIST 		= $(PROJECT)-$(VERSION).zip
BINDIST_CMD     = tar --transform=s@^$(BINDIST_DIR)@$(PROJECT)-$(VERSION)@ -czvf $(BINDIST) $(BINDIST_DIR)
W32BINDIST_CMD  = cd $(BINDIST_DIR) && zip -r ../$(W32BINDIST) * && cd $(BUILD_DIR)

# Check if called without a special build target
ifeq ($(NATIVE),)
  ifeq ($(CROSS),)
    ifeq ($(shell sh -c 'uname -o 2>/dev/null || echo not'),Cygwin)
      TARGETSYSTEM=CYGWIN
    else
      TARGETSYSTEM=LINUX
    endif
  endif
endif

# Linux 64-bit
ifeq ($(NATIVE), linux64)
  CXXFLAGS += -m64
  LDFLAGS += -m64
  TARGETSYSTEM=LINUX
else
  # Linux 32-bit
  ifeq ($(NATIVE), linux32)
    CXXFLAGS += -m32
    LDFLAGS += -m32
    TARGETSYSTEM=LINUX
  endif
endif

# OSX
ifeq ($(NATIVE), osx)
  # what is the lowest we even need?
  OSX_MIN = 10.5
  DEFINES += -DMACOSX
  CXXFLAGS += -mmacosx-version-min=$(OSX_MIN)
  WARNINGS = -Werror -Wall -Wextra -Wno-switch -Wno-sign-compare -Wno-missing-braces
  ifeq ($(LOCALIZE), 1)
    LDFLAGS += -lintl
    ifeq ($(MACPORTS), 1)
      CXXFLAGS += -I$(shell ncursesw5-config --includedir)
      LDFLAGS += -L$(shell ncursesw5-config --libdir)
    endif
  endif
  TARGETSYSTEM=LINUX
  ifneq ($(OS), Linux)
    BINDIST_CMD = tar -s"@^$(BINDIST_DIR)@$(PROJECT)-$(VERSION)@" -czvf $(BINDIST) $(BINDIST_DIR)
  endif
endif

# Win32 (MinGW32 or MinGW-w64(32bit)?)
ifeq ($(NATIVE), win32)
# Any reason not to use -m32 on MinGW32?
  TARGETSYSTEM=WINDOWS
else
  # Win64 (MinGW-w64? 64bit isn't currently working.)
  ifeq ($(NATIVE), win64)
    CXXFLAGS += -m64
    LDFLAGS += -m64
    TARGETSYSTEM=WINDOWS
  endif
endif

# Cygwin
ifeq ($(NATIVE), cygwin)
  TARGETSYSTEM=CYGWIN
endif

# MXE cross-compile to win32
ifneq (,$(findstring mingw32,$(CROSS)))
  DEFINES += -DCROSS_LINUX
  TARGETSYSTEM=WINDOWS
endif

# Global settings for Windows targets
ifeq ($(TARGETSYSTEM),WINDOWS)
  TARGET = $(W32TARGET)
  BINDIST = $(W32BINDIST)
  BINDIST_CMD = $(W32BINDIST_CMD)
  ODIR = $(W32ODIR)
  ifdef DYNAMIC_LINKING
    # Windows isn't sold with programming support, these are static to remove MinGW dependency.
    LDFLAGS += -static-libgcc -static-libstdc++
  else
    LDFLAGS += -static
  endif
  # verify we need this much stack space, or if it even matters
  W32FLAGS += -Wl,-stack,12000000,-subsystem,windows
  RFLAGS = -J rc -O coff
  ifeq ($(NATIVE), win64)
    RFLAGS += -F pe-x86-64
  endif
endif

ifdef LUA
  ifeq ($(TARGETSYSTEM),WINDOWS)
    # Windows expects to have lua unpacked at a specific location
    LDFLAGS += -llua
  else
    # On unix-like systems, use pkg-config to find lua
    LDFLAGS += $(shell pkg-config --silence-errors --libs lua5.2)
    CXXFLAGS += $(shell pkg-config --silence-errors --cflags lua5.2)
    LDFLAGS += $(shell pkg-config --silence-errors --libs lua-5.2)
    CXXFLAGS += $(shell pkg-config --silence-errors --cflags lua-5.2)
    LDFLAGS += $(shell pkg-config --silence-errors --libs lua)
    CXXFLAGS += $(shell pkg-config --silence-errors --cflags lua)
  endif

  CXXFLAGS += -DLUA
  LUA_DEPENDENCIES = $(LUASRC_DIR)/catabindings.cpp
  BINDIST_EXTRAS  += $(LUA_DIR)
endif


ifeq ($(TARGETSYSTEM),LINUX)
  LDFLAGS += -lncurses
endif

ifeq ($(TARGETSYSTEM),CYGWIN)
endif

# BSDs have backtrace() and friends in a separate library
ifeq ($(BSD), 1)
  LDFLAGS += -lexecinfo
endif

# Global settings for Windows targets (at end)
ifeq ($(TARGETSYSTEM),WINDOWS)
    LDFLAGS += -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lversion
endif

SOURCES = $(wildcard $(SRC_DIR)/*.cpp)
HEADERS = $(wildcard $(SRC_DIR)/*.h)
_OBJS = $(SOURCES:$(SRC_DIR)/%.cpp=%.o)
ifeq ($(TARGETSYSTEM),WINDOWS)
  RSRC = $(wildcard $(SRC_DIR)/*.rc)
  _OBJS += $(RSRC:$(SRC_DIR)/%.rc=%.o)
endif
OBJS = $(patsubst %,$(ODIR)/%,$(_OBJS))

ifeq ($(TARGETSYSTEM), LINUX)
  ifneq ($(PREFIX),)
    DEFINES += -DPREFIX="$(PREFIX)"
  endif
endif

ifeq ($(TARGETSYSTEM), CYGWIN)
  ifneq ($(PREFIX),)
    DEFINES += -DPREFIX="$(PREFIX)"
  endif
endif

all: version $(TARGET)
	@

#$(TARGET): $(ODIR) $(DDIR) $(OBJS)
#	$(LD) $(W32FLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)

#$(TARGET).a: $(ODIR) $(DDIR) $(OBJS)
$(TARGET): $(ODIR) $(DDIR) $(OBJS)
	ar rcs $(TARGET).a $(filter-out $(ODIR)/main.o,$(OBJS))

.PHONY: version
version:
	@( VERSION_STRING=$(VERSION) ; \
            [ -e ".git" ] && GITVERSION=$$( git describe --tags --always --dirty --match "[0-9A-Z]*.[0-9A-Z]*" ) && VERSION_STRING=$$GITVERSION ; \
            [ -e "$(SRC_DIR)/version.h" ] && OLDVERSION=$$(grep VERSION $(SRC_DIR)/version.h|cut -d '"' -f2) ; \
            if [ "x$$VERSION_STRING" != "x$$OLDVERSION" ]; then echo "#define VERSION \"$$VERSION_STRING\"" | tee $(SRC_DIR)/version.h ; fi \
         )
$(ODIR):
	mkdir -p $(ODIR)

$(DDIR):
	@mkdir $(DDIR)

$(ODIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CPPFLAGS) $(DEFINES) $(CXXFLAGS) -c $< -o $@

$(ODIR)/%.o: $(SRC_DIR)/%.rc
	$(RC) $(RFLAGS) $< -o $@

version.cpp: version

#$(LUASRC_DIR)/catabindings.cpp: $(LUA_DIR)/class_definitions.lua $(LUASRC_DIR)/generate_bindings.lua
#	cd $(LUASRC_DIR) && $(LUA_BINARY) generate_bindings.lua

#$(SRC_DIR)/catalua.cpp: $(LUA_DEPENDENCIES)

clean: clean-tests
	rm -rf $(TARGET) $(W32TARGET) $(TARGET).a
	rm -rf $(ODIR) $(W32ODIR)
	rm -rf $(BINDIST) $(W32BINDIST) $(BINDIST_DIR)
	rm -f $(SRC_DIR)/version.h

distclean:
	rm -rf $(BINDIST_DIR)

bindist: $(BINDIST)

ifeq ($(TARGETSYSTEM), LINUX)
DATA_PREFIX=$(PREFIX)/share/$(TARGET_NICK)/
BIN_PREFIX=$(PREFIX)/bin
install: version $(TARGET)
	mkdir -p $(DATA_PREFIX)
	mkdir -p $(BIN_PREFIX)
	install --mode=755 $(TARGET) $(BIN_PREFIX)
ifdef LUA
	mkdir -p $(DATA_PREFIX)/lua
	install --mode=644 lua/autoexec.lua $(DATA_PREFIX)/lua
	install --mode=644 lua/class_definitions.lua $(DATA_PREFIX)/lua
endif
	install --mode=644 data/changelog.txt README.txt LICENSE.txt -t $(DATA_PREFIX)
endif

ifeq ($(TARGETSYSTEM), CYGWIN)
DATA_PREFIX=$(PREFIX)/share/$(TARGET_NICK)/
BIN_PREFIX=$(PREFIX)/bin
install: version $(TARGET)
	mkdir -p $(DATA_PREFIX)
	mkdir -p $(BIN_PREFIX)
	install --mode=755 $(TARGET) $(BIN_PREFIX)
ifdef LUA
	mkdir -p $(DATA_PREFIX)/lua
	install --mode=644 lua/autoexec.lua $(DATA_PREFIX)/lua
	install --mode=644 lua/class_definitions.lua $(DATA_PREFIX)/lua
endif
	install --mode=644 data/changelog.txt README.txt LICENSE.txt -t $(DATA_PREFIX)
endif

ifdef TILES
ifeq ($(NATIVE), osx)
APPTARGETDIR=$(TARGET).app
APPRESOURCESDIR=$(APPTARGETDIR)/Contents/Resources
APPDATADIR=$(APPRESOURCESDIR)/data

appclean:
	rm -rf $(APPTARGETDIR)

#data/osx/AppIcon.icns: data/osx/AppIcon.iconset
#	iconutil -c icns $<

#app: appclean version data/osx/AppIcon.icns $(TILESTARGET)
  #mkdir -p $(APPTARGETDIR)/Contents
  #cp data/osx/Info.plist $(APPTARGETDIR)/Contents/
  #mkdir -p $(APPTARGETDIR)/Contents/MacOS
  #cp data/osx/Cataclysm.sh $(APPTARGETDIR)/Contents/MacOS/
  #mkdir -p $(APPRESOURCESDIR)
  #cp $(TILESTARGET) $(APPRESOURCESDIR)/
  #cp data/osx/AppIcon.icns $(APPRESOURCESDIR)/
  #mkdir -p $(APPDATADIR)
  #cp data/fontdata.json $(APPDATADIR)
  #cp -R data/font $(APPDATADIR)
  #cp -R data/json $(APPDATADIR)
  #cp -R data/mods $(APPDATADIR)
  #cp -R data/names $(APPDATADIR)
  #cp -R data/raw $(APPDATADIR)
  #cp -R data/recycling $(APPDATADIR)
  #cp -R data/motd $(APPDATADIR)
  #cp -R data/credits $(APPDATADIR)
  #cp -R data/title $(APPDATADIR)
 
endif  # ifeq ($(NATIVE), osx)
endif  # ifdef TILES

$(BINDIST): distclean version $(TARGET) $(BINDIST_EXTRAS)
	mkdir -p $(BINDIST_DIR)
	cp -R $(TARGET) $(BINDIST_EXTRAS) $(BINDIST_DIR)
	$(BINDIST_CMD)

export ODIR _OBJS LDFLAGS CXX W32FLAGS DEFINES CXXFLAGS

ctags: $(SOURCES) $(HEADERS)
	ctags $(SOURCES) $(HEADERS)

etags: $(SOURCES) $(HEADERS)
	etags $(SOURCES) $(HEADERS)
	find data -name "*.json" -print0 | xargs -0 -L 50 etags --append

tests: $(TARGET).a
	$(MAKE) -C tests

check: $(TARGET).a
	$(MAKE) -C tests check

clean-tests:
	$(MAKE) -C tests clean

.PHONY: tests check ctags etags clean-tests install

-include $(SOURCES:$(SRC_DIR)/%.cpp=$(DEPDIR)/%.P)
-include ${OBJS:.o=.d}
