

LIST_SUB-clean=remove-source

define gen-sub-target
.PHONY: $(1)/$(2)
$(1)/$(2): FORCE
	$$(SUBMAKE) -C $(1) $(2)

LIST_SUB-$(2)+= $(1)/$(2)
endef

define gen-glob-target
$(1): $(LIST_SUB-$(1))
endef

$(foreach _dir,$(SUB_DIRS),$(foreach _rule,$(ALL_RULES),$(eval $(call gen-sub-target,$(_dir),$(_rule)))))

warn-usage:
	$(QUIET) echo "The next install must be run separately, in the folder itself, with sudo"

ttyecho/install: warn-usage

$(foreach _rule,$(ALL_RULES),$(eval $(call gen-glob-target,$(_rule))))