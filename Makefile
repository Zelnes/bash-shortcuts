
TOPDIR=$(shell pwd)
export TOPDIR

.PHONY: FORCE

home work : | common
bash: git

include rules.mk
include targets.mk

source-final:
	$(QUIET) $(call CMESSAGE,_B,*** You can now add to your ~/.bashrc : )
	$(QUIET) $(call CMESSAGE,_B,*** source $$(realpath $(SOURCE_FILE)))

install: source-final
