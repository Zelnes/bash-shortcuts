SOURCE_FILE=$(TOPDIR)/extra-sources.sh
export SOURCE_FILE

empty=
space=$(empty) $(empty)

TMP_FILE=TMP_FILE


_Y:=\\033[33m
_B:=\\033[37m
_N:=\\033[m

define CMESSAGE
	printf "$($(1))%s$(_N)\n" "$(2)"
endef

define MESSAGE
	$(call CMESSAGE,_Y,$(1))
endef

ifneq ($(_DIR),)
	FOO__=$(shell ))
endif

ifeq ($(V),s)
SUBMAKE=$(MAKE)
else
QUIET=@
define SUBMAKE
@cmd() { $(call MESSAGE,  make[$(MAKELEVEL)] $$*); $(MAKE) --no-print-directory $$* 1>/dev/null; }; cmd
endef
endif

RM=$(QUIET) rm -f

SUB_MAKEFILES=$(wildcard ./*/Makefile)
SUB_DIRS=$(subst ./,,$(subst / , ,$(dir $(SUB_MAKEFILES)) ))
SUB_DIRS_RESEARCH=_$(subst $(space),_,$(SUB_DIRS))_

define gen-var-targets-sourcing
files-$(1)=$$(strip $$(wildcard $(1)/*.sh))
$(1):
	$$(foreach _f,$$(files-$(1)),echo "source $$(realpath $$(_f))" >>$(TMP_FILE);)
endef

# Param 1 : file to source
define Add/Source/File/Environment
	echo "source $$(realpath $(1))" >>$(SOURCE_FILE)
endef

# Param 1 : Directory that is added to the PATH variable
define Append/Directory/Global/Path
	echo "PATH=\"\$${PATH}:$$(realpath $(1))\"" >>$(SOURCE_FILE)
endef

export Add/Source/File/Environment Append/Directory/Global/Path

ALL_RULES=home work install common clean
ALL_REAL_RULES=$(filter-out install clean,$(ALL_RULES))

.PHONY: $(ALL_RULES)

remove-TMP:
	$(RM) $(TMP_FILE)

remove-source:
	$(RM) $(SOURCE_FILE)

clean: remove-TMP
