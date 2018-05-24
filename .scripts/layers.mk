# Copyright (C) 2018, TQ Systems
# Matthias Schiffer <matthias.schiffer@tq-group.com>

include em-layers.conf
-include local/em-layers.conf


# Targets:
#
# - update: updates all layers defined in em-layers.conf and local/em-layers.conf
# - show-bblayers: outputs a bblayers.conf including all layers defined in em-layers and local/em-layers.conf
# - show-git-server: outputs the TQ git server base path


git = git -C 'layers/$(1)'

# Resolves to the value of the given variable if it is properly defined (not undefined or inherited from environment)
ifset = $(if $(filter-out undefined environment,$(origin $(1))),$($(1)))

define update-layer
	echo 'Updating layer $(1)...'

	[ -d 'layers/$(1)' ] || git clone '$($(1)_repo)' -b '$($(1)_branch)' 'layers/$(1)'

	# Update repo URL
	$(git) remote set-url origin '$($(1)_repo)'

	# Skip fetch if a specific commit is requested that is already available
	if [ -z '$(call ifset,$(1)_commit)' ] || ! ($(git) show --oneline --no-patch '$($(1)_commit)^{commit}' -- >/dev/null 2>&1); then \
		$(git) fetch --tags --prune origin; \
	fi

	# If we do not need a specific commit, use base branch
	$(git) checkout '$(if $(call isset,$(1)_commit),$($(1)_commit),origin/$($(1)_branch))' -B '$($(1)_branch)'
endef

define update-layers
	$(foreach layer,$(LAYERS),
		$(if $(call ifset,$(layer)_repo),
			$(call update-layer,$(layer)),
			echo 'Skipping layer $(layer)'
		)
	)
endef

update:
	mkdir -p layers
	$(update-layers)


layer-dirs = $(if $($(1)_subdirs),$(foreach dir,$($(1)_subdirs),$(1)/$(dir)),$(1))
all-dirs = $(foreach layer,$(LAYERS),$(call layer-dirs,$(layer)))

export define bblayers
# Do not edit! This file is managed automatically by em-build-env.

BBPATH = "$${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
 $(foreach dir,$(all-dirs), $${TOPDIR}/../layers/$(dir) \\
)  "
endef

show-bblayers:
	echo "$$bblayers"

show-git-server:
	echo '$(GIT_SERVER)'

.PHONY: update show-bblayers show-git-server
.SILENT:
