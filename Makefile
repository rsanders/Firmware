###############################################################################
#
# Copyright 2014, ACSE & CADIEEL
#    ACSE   : http://www.sase.com.ar/asociacion-civil-sistemas-embebidos/ciaa/
#    CADIEEL: http://www.cadieel.org.ar
#
# This file is part of CIAA Firmware.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
###############################################################################
######################## DO NOT CHANGE THIS FILE ##############################
###############################################################################
# You dont have to change this file, never.
#
# Copy Makefile.config to Makefile.mine and set the variables.
#
# Makefile.mine will be included by this root Makefile and your configurations
# in Makefile.mine will be ignored due to .gitignore.
#
# Please take into account to check and compare your Makefile.mine every time
# that Makefile.config is updated, you may have to adapt your Makefile.mine
# if Makefile.config is changed.
#
###############################################################################
-include Makefile.mine
###############################################################################
# ARCH, CPUTYPE and CPU following are supported
# +--------------+---------------+---------------+--------------+
# |      ARCH    |    CPUTYPE    |      CPU      | COMPILER     |
# +--------------+---------------+---------------+--------------+
# | win          | win32         |               | gcc          |
# +--------------+---------------+---------------+--------------+
# | posix        | posix32       |               | gcc          |
# |              | posix64       |               |              |
# +--------------+---------------+---------------+--------------+
# | cortexM4     | lpc4000       | lpc4337       |              |
# +--------------+---------------+---------------+--------------+
#
ARCH 				?= win
CPUTYPE 			?= win32
CPU 				?=
COMPILER			?= gcc

DS 					?= /
# MODULES
#
# Available modules are:
# examples/blinking
# modules/posix
#
MODS ?= modules$(DS)posix      			\
		modules$(DS)ciaak				\
		modules$(DS)config				\
        modules$(DS)bsp					\
        modules$(DS)platforms 			\
		modules$(DS)rtos				\
        examples$(DS)blinking_make

###############################################################################
# get OS
#
# This part of the makefile is used to detect your OS. Depending on the OS
# the rule cyg2win may adapt the paths to windows if needed.
ifeq ($(OS),Windows_NT)
# WINDOWS
# Command line separator
CS             = &&
# Command for multiline echo
MULTILINE_ECHO = echo -e
define cyg2win
`cygpath -w $(1)`
endef
else
# NON WINDOWS OS
# Command line separator
CS					= ;
# Comand for multiline echo
MULTILINE_ECHO = echo -n
define cyg2win
$(1)
endef
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		# LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		# MACOS
	endif
endif
###############################################################################
# get root dir
ROOT_DIR := $(shell pwd)
# out dir
OUT_DIR	= $(ROOT_DIR)$(DS)out
# object dir
OBJ_DIR  = $(OUT_DIR)$(DS)obj
# lib dir
LIB_DIR	= $(OUT_DIR)$(DS)lib
# bin dir
BIN_DIR	= $(OUT_DIR)$(DS)bin

# include needed modules
include $(foreach module, $(MODS), $(module)$(DS)mak$(DS)Makefile)

.DEFAULT_GOAL := $(project)

# add include files
INCLUDE += $(foreach LIB, $(LIBS), $($(LIB)_INC_PATH))
CFLAGS  += -ggdb -Wall -Werror
CFLAGS  += $(foreach inc, $(INCLUDE), -I$(inc))
CFLAGS  += -DARCH=$(ARCH) -DCPUTYPE=$(CPUTYPE) -DCPU=$(CPU)


# create list of object files
$(foreach LIB, $(LIBS), $(eval $(LIB)_OBJ_FILES = $($(LIB)_SRC_FILES:.c=.o)) )


#rule for library
define librule
$(LIB_DIR)$(DS)$(strip $(1)).a : $(2)
	@echo ===============================================================================
	@echo Creating library $(1)
	$(AR) -rcs -o $(LIB_DIR)$(DS)$(strip $(1)).a $(2)
endef


OBJ_FILES = $(SRC_FILES:.c=.o)

# create rule for library
# lib.a : lib_OBJ_FILES.o
$(foreach LIB, $(LIBS), $(eval $(call librule, $(LIB), $($(LIB)_OBJ_FILES))) )

$(foreach LIB, $(LIBS), $(eval $(LIB) : $(LIB_DIR)$(DS)$(LIB).a ) )

###################### START UNIT TEST PART OF MAKE FILE ######################
# Gets all Modules Names
DIRS := $(sort $(dir $(wildcard modules$(DS)*$(DS))))
ALL_MODS := $(subst modules, , $(DIRS))
ALL_MODS := $(subst $(DS), , $(ALL_MODS))

MOCKS_OUT_DIR = out$(DS)ceedling$(DS)mocks

FILES_TO_MOCK = $(foreach DIR, $(DIRS), $(wildcard $(DIR)inc$(DS)*.h))

FILES_MOCKED = $(foreach MOCKED, $(FILES_TO_MOCK), $(MOCKS_OUT_DIR)$(DS)mock_$(notdir $(MOCKED)))


###############################################################################
# rule for tst_<mod>[_file]
ifeq ($(findstring tst_, $(MAKECMDGOALS)),tst_)

# get module to be tested and store it in tst_mod variable
tst_mod = $(firstword $(filter-out tst,$(subst _, ,$(MAKECMDGOALS))))

# get file to be tested (if present) and store it in tst_file
tst_file := $(word 2,$(filter-out tst,$(subst _, ,$(MAKECMDGOALS))))
ifneq ($(word 3,$(filter-out tst,$(subst _, ,$(MAKECMDGOALS)))),)
tst_file := $(join $(tst_file),_$(word 3,$(filter-out tst,$(subst _, ,$(MAKECMDGOALS)))))
endif

# include corresponding makefile
include modules$(DS)$(tst_mod)$(DS)mak$(DS)Makefile
# include test makefile
include modules$(DS)$(tst_mod)$(DS)mtest$(DS)mak$(DS)Makefile

# get list of unit test sources
ifneq ($(tst_file),)
# definitions if to run only a specific unit test

# include modules needed for this module
include $(foreach mod,$($(tst_mod)_TST_MOD),modules$(DS)$(mod)$(DS)mak$(DS)Makefile)

MTEST_SRC_FILES = $($(tst_mod)_PATH)$(DS)mtest$(DS)src$(DS)test_$(tst_file).c

UNITY_INC = externals$(DS)ceedling$(DS)vendor$(DS)unity$(DS)src                  	\
				externals$(DS)ceedling$(DS)vendor$(DS)cmock$(DS)src                  	\
				out$(DS)ceedling$(DS)mocks                                           	\
				$(foreach mod,$($(tst_mod)_TST_MOD),$($(mod)_INC_PATH))						\
				$($(tst_mod)_TST_INC_PATH)																\
				$($(tst_mod)_INC_PATH)

UNITY_SRC = modules$(DS)$(tst_mod)$(DS)mtest$(DS)src$(DS)test_$(tst_file).c 			\
				modules$(DS)$(tst_mod)$(DS)mtest$(DS)src$(DS)test_$(tst_file)_Runner.c	\
				modules$(DS)$(tst_mod)$(DS)src$(DS)$(tst_file).c								\
				externals$(DS)ceedling$(DS)vendor$(DS)unity$(DS)src$(DS)unity.c 			\
				externals$(DS)ceedling$(DS)vendor$(DS)cmock$(DS)src$(DS)cmock.c 			\
				$(foreach file,$(filter-out $(tst_file).c,$(notdir $($(tst_mod)_SRC_FILES))), out$(DS)ceedling$(DS)mocks$(DS)mock_$(file))

CFLAGS  = -ggdb #-Wall -Werror #see issue #28
CFLAGS  += $(foreach inc, $(UNITY_INC), -I$(inc))
CFLAGS  += -DARCH=$(ARCH) -DCPUTYPE=$(CPUTYPE) -DCPU=$(CPU) -DUNITY_EXCLUDE_STDINT_H

else
# get all test target for the selected module
MTEST := $(notdir $(wildcard $($(tst_mod)_PATH)$(DS)mtest$(DS)src$(DS)test_*.c))
MTEST := $(subst test_,,$(MTEST))
MTEST := $(subst .c,,$(MTEST))
MTEST := $(foreach tst, $(MTEST),tst_$(tst_mod)_$(tst))


endif

tst_link: $(UNITY_SRC:.c=.o)
	@echo ===============================================================================
	@echo Linking Test
	gcc $(UNITY_SRC:.c=.o) -o out/bin/test.bin

# rule for tst_<mod>_<file>
tst_$(tst_mod)_$(tst_file): $(MTEST_SRC_FILES:.c=_Runner.c) tst_link
	@echo ===============================================================================
	@echo Testing from module $(tst_mod) the file $(tst_file)
	out/bin/test.bin

# rule for tst_<mod>
tst_$(tst_mod):
	@echo ===============================================================================
	@echo Testing the module $(tst_mod)
	@echo Testing $(MTEST)
	$(foreach tst,$(MTEST),make $(tst) $(CS))


#tst_$(tst_mod): $(MTEST_SRC_FILES:.c=_Runner.c) tst_link
#	@echo ===============================================================================
#	@echo Testing the module $(tst_mod)
#	@$(MULTILINE_ECHO) "Testing following .c Files: \n $(foreach src, $($(tst_mod)_SRC_FILES),     $(src)\n)"
#	@$(MULTILINE_ECHO) "Following Unity Test found: \n $(foreach src, $(MTEST_SRC_FILES),     $(src)\n)"
#	out/bin/test.bin

endif

###############################################################################
# rule to generate the mocks
mocks:
	@echo ===============================================================================
	@$(MULTILINE_ECHO) "Creating Mocks for: \n $(foreach mock, $(FILES_TO_MOCK),     $(mock)\n)"
	ruby externals/ceedling/vendor/cmock/lib/cmock.rb -omodules/tools/ceedling/project.yml $(FILES_TO_MOCK)

###############################################################################
# rule to inform abotu all available tests
tst:
	@echo "+-----------------------------------------------------------------------------+"
	@echo "|               Unit Tests                                                    |"
	@echo "+-----------------------------------------------------------------------------+"
	@$(MULTILINE_ECHO) "Following tst rules have been created:\n $(foreach TST,$(ALL_MODS),     tst_$(TST): run unit tests of $(TST)\n)"

test_%_Runner.c : test_%.c
	@echo ===============================================================================
	@echo Creating Runner for $<
	@echo "                 in $@"
	ruby externals$(DS)ceedling$(DS)vendor$(DS)unity$(DS)auto$(DS)generate_test_runner.rb $< modules$(DS)tools$(DS)ceedling$(DS)project.yml

unity:
	@echo ===============================================================================
	@echo Running unity for $(UNITY)
#	@echo Running for following files $(foreach )
#ruby externals/ceedling/vendor/unity/auto/generate_test_runner.rb summ/mtest/test_summ.c project.yml



###################### ENDS UNIT TEST PART OF MAKE FILE #######################

# Rule to compile
%.o : %.c
	@echo ===============================================================================
	@echo Compiling $<
	$(CC) -c $(CFLAGS) $< -o $@

# link rule

$(project) : $(LIBS) $(OBJ_FILES)
	@echo ===============================================================================
	@echo Linking $(project)
	$(CC) $(OBJ_FILES) $(foreach lib, $(LIBS), $(LIB_DIR)$(DS)$(lib).a) -o $(BIN_DIR)$(DS)$(project).bin $(LFLAGS)
#	$(LD) -lcrt1 -Map $(BIN_DIR)$(DS)$(project).map --library-path=$(LIB_DIR)$(DS) $(OBJ_FILES) $(foreach lib, $(LIB_DIR)$(DS)$(LIBS).a, $(lib)) -o $(BIN_DIR)$(DS)$(project).bin


###############################################################################
# rtos OSEK generation
GENDIR			= out$(DS)gen
generate : $(OIL_FILES)
		php modules$(DS)rtos$(DS)generator$(DS)generator.php --cmdline -l -v -c \
			$(call cyg2win,$(OIL_FILES)) -f $(foreach TMP, $(rtos_GEN_FILES), $(call cyg2win,$(TMP))) -o $(GENDIR)

###############################################################################
# doxygen
doxygen:
	@echo running doxygen
	doxygen modules/tools/doxygen/doxygen.cnf

###############################################################################
# help
help:
	@echo "+-----------------------------------------------------------------------------+"
	@echo "|               General Help                                                  |"
	@echo "+-----------------------------------------------------------------------------+"
	@echo info.......: general information about the make environment
	@echo info_\<mod\>.: same as info but reporting information of a library
	@echo generate...: generates the ciaaRTOS
	@echo "+-----------------------------------------------------------------------------+"
	@echo "|               Unit Tests                                                    |"
	@echo "+-----------------------------------------------------------------------------+"
	@echo mocks......: generate the mocks for all header files
	@echo tst........: displays possible tests
	@echo tst_\<mod\>..: runs the tests of the indicated module

###############################################################################
# info for  aspecific module
ifeq ($(findstring info_, $(MAKECMDGOALS)),info_)
info_mod = $(subst info_,,$(MAKECMDGOALS))
# include corresponding makefile
include modules$(DS)$(info_mod)$(DS)mak$(DS)Makefile

# create the corresponding info_<mod> rule
info_$(info_mod) :
	@echo ===============================================================================
	@echo Info of $(info_mod)
	@echo Path........: $($(info_mod)_PATH)
	@echo Include path: $($(info_mod)_INC_PATH)
	@echo Source path.: $($(info_mod)_SRC_PATH)
	@$(MULTILINE_ECHO) "Source files:\n $(foreach src, $($(info_mod)_SRC_FILES),     $(src)\n)"
endif

###############################################################################
# information
info:
	@echo "+-----------------------------------------------------------------------------+"
	@echo "|               Enable Config Info                                            |"
	@echo "+-----------------------------------------------------------------------------+"
	@echo ARCH/CPUTYPE/CPU...: $(ARCH)/$(CPUTYPE)/$(CPU)
	@echo enable modules.....: $(MODS)
	@echo libraries..........: $(LIBS)
	@echo use make info_\<mod\>: to get information of a specific module. eg: make info_posix
	@echo "+-----------------------------------------------------------------------------+"
	@echo "|               All available modules                                         |"
	@echo "+-----------------------------------------------------------------------------+"
	@echo modules............: $(ALL_MODS)
	@echo "+-----------------------------------------------------------------------------+"
	@echo "|               Compiler Info                                                 |"
	@echo "+-----------------------------------------------------------------------------+"
	@echo Compiler...........: $(COMPILER)
	@echo CC.................: $(CC)
	@echo AR.................: $(AR)
	@echo LD.................: $(LD)
	@echo Compile Flags......: $(CFLAGS)

###############################################################################
# clean
.PHONY: clean
clean:
	@echo Removing libraries
	@rm -rf $(LIB_DIR)$(DS)*
	@echo Removing bin filei\(s\)
	@rm -rf $(BIN_DIR)$(DS)*
	@echo Removing RTOS generated files
	@rm -rf $(GENDIR)$(DS)*
	@echo Removing object files
	@find -name "*.o" -exec rm {} \;
	@echo Removing Unity Runners files
	@find -name "*_Runner.c" -exec rm {} \;

###############################################################################
# doc -> documentation
doc: doxygen
	@echo Generating CIAA Firmware documentation
	@echo This rule is still not implemented see: https://github.com/ciaa/Firmware/issues/10
	@exit 1