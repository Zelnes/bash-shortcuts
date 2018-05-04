TOPDIR?=..
include $(TOPDIR)/rules.mk

$(foreach _rule,$(ALL_REAL_RULES),$(eval $(call gen-var-targets-sourcing,$(_rule))))

install:
	cat $(TMP_FILE) >>$(SOURCE_FILE)