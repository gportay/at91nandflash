#include kbuild.mk

# SUBARCH tells the usermode build what the underlying arch is.  That is set
# first, and if a usermode build is happening, the "ARCH=um" on the command
# line overrides the setting of ARCH below.  If a native build is happening,
# then ARCH is assigned, getting whatever value it gets normally, and
# SUBARCH is subsequently ignored.

SUBARCH := $(shell uname -m | sed -e s/i.86/x86/ -e s/x86_64/x86/ \
				  -e s/sun4u/sparc64/ \
				  -e s/arm.*/arm/ -e s/sa110/arm/ \
				  -e s/s390x/s390/ -e s/parisc64/parisc/ \
				  -e s/ppc.*/powerpc/ -e s/mips.*/mips/ \
				  -e s/sh[234].*/sh/ -e s/aarch64.*/arm64/ )

# Cross compiling and selecting different set of gcc/bin-utils
# ---------------------------------------------------------------------------
#
# When performing cross compilation for other architectures ARCH shall be set
# to the target architecture. (See arch/* for the possibilities).
# ARCH can be set during invocation of make:
# make ARCH=ia64
# Another way is to have ARCH set in the environment.
# The default ARCH is the host where make is executed.

# CROSS_COMPILE specify the prefix used for all executables used
# during compilation. Only gcc and related bin-utils executables
# are prefixed with $(CROSS_COMPILE).
# CROSS_COMPILE can be set on the command line
# make CROSS_COMPILE=ia64-linux-
# Alternatively CROSS_COMPILE can be set in the environment.
# A third alternative is to store a setting in .config so that plain
# "make" in the configured kernel build directory always uses that.
# Default value for CROSS_COMPILE is not to prefix executables
# Note: Some architectures assign CROSS_COMPILE in their arch/*/Makefile

###CROSS_COMPILE ?=
#### bbox: we may have CONFIG_CROSS_COMPILER_PREFIX in .config,
#### and it has not been included yet... thus using an awkward syntax.
###ifeq ($(CROSS_COMPILE),)
###CROSS_COMPILE := $(shell grep ^CONFIG_CROSS_COMPILER_PREFIX $(KCONFIG_CONFIG) 2>/dev/null)
###CROSS_COMPILE := $(subst CONFIG_CROSS_COMPILER_PREFIX=,,$(CROSS_COMPILE))
###CROSS_COMPILE := $(subst ",,$(CROSS_COMPILE))
####")
###endif

#### SUBARCH tells the usermode build what the underlying arch is.  That is set
#### first, and if a usermode build is happening, the "ARCH=um" on the command
#### line overrides the setting of ARCH below.  If a native build is happening,
#### then ARCH is assigned, getting whatever value it gets normally, and
#### SUBARCH is subsequently ignored.

###ifneq ($(CROSS_COMPILE),)
###SUBARCH := $(shell echo $(CROSS_COMPILE) | cut -d- -f1)
###else
###SUBARCH := $(shell uname -m)
###endif
###SUBARCH := $(shell echo $(SUBARCH) | sed -e s/i.86/x86/ -e s/x86_64/x86/ \
###					 -e s/sun4u/sparc64/ \
###					 -e s/arm.*/arm/ -e s/sa110/arm/ \
###					 -e s/s390x/s390/ -e s/parisc64/parisc/ \
###					 -e s/ppc.*/powerpc/ -e s/mips.*/mips/ \
###					 -e s/sh[234].*/sh/ -e s/aarch64.*/arm64/ )

ARCH		?= $(SUBARCH)
CROSS_COMPILE	?= $(CONFIG_CROSS_COMPILE:"%"=%)

# Architecture as present in compile.h
UTS_MACHINE 	:= $(ARCH)
SRCARCH 	:= $(ARCH)
