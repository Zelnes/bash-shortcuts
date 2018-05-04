TOPDIR?=..
include $(TOPDIR)/rules.mk

define gen-var-targets
$(1):
	@echo "PATH=\"\$$$${PATH}:$$(realpath $(1))\"" >>$(TMP_FILE)
endef

$(foreach _rule,$(ALL_REAL_RULES),$(eval $(call gen-var-targets,$(_rule))))

install:
	cat $(TMP_FILE) >>$(SOURCE_FILE)
