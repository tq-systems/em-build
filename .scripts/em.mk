# Copyright (C) 2018, TQ Systems
# Matthias Schiffer <matthias.schiffer@tq-group.com>

include em-layers.conf
-include local/em-layers.conf


# Targets:
#
# - update: updates all layers defined in em-layers.conf and local/em-layers.conf
# - show-bblayers: outputs a bblayers.conf including all layers defined in em-layers and local/em-layers.conf


git = git -C '$(2)'

# Resolves to the value of the given variable if it is properly defined (not undefined or inherited from environment)
ifset = $(if $(filter-out undefined environment,$(origin $(1))),$($(1)))

define update-repo
	echo 'Updating $(2)...'

	[ -d '$(2)' ] || git clone '$($(1)_repo)' -b '$($(1)_branch)' '$(2)'

	# Update repo URL
	$(git) remote set-url origin '$($(1)_repo)'

	# Skip fetch if a specific commit is requested that is already available
	if [ -z '$(call ifset,$(1)_commit)' ] || ! ($(git) show --oneline --no-patch '$($(1)_commit)^{commit}' -- >/dev/null 2>&1); then \
		$(git) fetch --tags --prune origin; \
	fi

	# If we do not need a specific commit, use base branch
	$(git) checkout '$(if $(call ifset,$(1)_commit),$($(1)_commit),origin/$($(1)_branch))' -B '$($(1)_branch)'
endef

define update-layers
	$(foreach layer,$(LAYERS),
		$(if $(call ifset,$(layer)_repo),
			$(call update-repo,$(layer),layers/$(layer)),
			echo 'Skipping layers/$(layer)'
		)
	)
endef

update:
	mkdir -p layers
	$(call update-repo,bitbake,bitbake)
	$(update-layers)


layer-dirs = $(if $($(1)_subdirs),$(foreach dir,$($(1)_subdirs),$(1)/$(dir)),$(1))
all-dirs = $(foreach layer,$(LAYERS),$(call layer-dirs,$(layer)))

EMPTY =
BS = \$(EMPTY)

export define bblayers
# Do not edit! This file is managed automatically by em-build-env.

BBPATH = "$${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " $(BS)
 $(foreach dir,$(all-dirs), $${TOPDIR}/../layers/$(dir) $(BS)
)  "
endef

show-bblayers:
	printf '%s\n' "$$bblayers"

.PHONY: update show-bblayers
.SILENT:
