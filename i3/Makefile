TOPDIR?=..
include $(TOPDIR)/rules.mk

ifneq ($(findstring $(MAKECMDGOALS),_home_work_),)
-include $(MAKECMDGOALS)/make.mk
endif

TARGET_CONF=$(shell echo $${HOME}/.config/i3/config)
TARGET_BACK=$(TARGET_CONF)_backup
SCREEN_DIR=$(shell realpath $${HOME}/i3_Screenshot)
BACKGROUND_FILE=$(shell realpath ./images/background.png)

.PHONY: $(current)/prereq $(current)/common $(current)/install $(current)/work $(current)/home

PREREQ_LIST+=scrot
prereq:
	@$(foreach pre,$(PREREQ_LIST),$(if $(shell which $(pre)),,$(error "You need to install '$(pre)' before")))
	@mkdir -p $(SCREEN_DIR)

# Param 1 : Config file to import
# Param 2 : Config file to put in
define import-config
	echo "" >>"$(2)"
	echo "###" >>"$(2)"
	echo "# Importing config from $$(realpath $1)" >>"$(2)"
	echo "###" >>"$(2)"
	echo "" >>"$(2)"
	[ -f "$(1)" ] && cat "$(1)" >>"$(2)" || echo "# No conf $(1)" >>"$(2)"
endef

# Param 1 : File to replace in
# Param 2 : Value to replace (__TO_REPLACE__)
# Param 3 : Value to put inplace
define replace-in-file
	sed -i 's|__TO_REPLACE__$(2)|$(3)|' $(1)
endef

common: prereq
	$(RM) $(TMP_FILE)
	$(QUIET) $(call import-config,common/config,$(TMP_FILE))

replace-values:
	$(QUIET) $(call replace-in-file,$(TMP_FILE),STATUS,py3status -c $(shell realpath $(TOPDIR)/i3/common/i3status.conf))
	$(QUIET) $(call replace-in-file,$(TMP_FILE),EXIT,$(shell realpath common/i3exit) "$(BACKGROUND_FILE)")
	$(QUIET) $(call replace-in-file,$(TMP_FILE),SCREENSHOT,$(SCREEN_DIR))
	$(QUIET) $(call replace-in-file,$(TMP_FILE),COMMON_BIN,$(shell realpath $(TOPDIR)/bin/common))

install: replace-values
	$(QUIET) [ -h "$(TARGET_CONF)" ] && rm "$(TARGET_CONF)"; :
	$(QUIET) [ -f "$(TARGET_CONF)" ] && { \
		echo "$(TARGET_CONF) exists. Saving it to $(TARGET_BACK)"; \
		mv "$(TARGET_CONF)" "$(TARGET_BACK)"; \
	}; :
	$(QUIET) ln -nsf "$$(realpath $(TMP_FILE))" "$(TARGET_CONF)"
	$(QUIET) echo "Current config is now installed under $(TARGET_CONF)"

work home:
	$(QUIET) $(call import-config,$@/config,$(TMP_FILE))
	$(QUIET) $(call replace-in-file,$(TMP_FILE),$(call upperCase,$@)_BIN,$(shell realpath $(TOPDIR)/bin/$@))

clean:
	$(QUIET) [ -h "$(TARGET_CONF)" ] && rm "$(TARGET_CONF)"; :
	$(QUIET) [ -f "$(TARGET_BACK)" ] && { \
		echo "Reset backup $(TARGET_BACK) to $(TARGET_CONF)"; \
		mv "$(TARGET_BACK)" "$(TARGET_CONF)"; \
	}; :