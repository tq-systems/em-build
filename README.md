# em-build
## Description
This project contains the Energy Manager OS (EMOS) & EM SDK build scripts.

The configuration files and scripts in this repository are used to set up the
Yocto-based build environment for the EM SDK, while also allowing to add custom
layers to the bulid configuration.

## Build
Two scripts are provided.

The `em-update`script clones or updates the git repositories for the used Yocto layers in the `layers` subdirectory, as configured in `em-layers.conf`.

The `em-build-env` script must be sourced by the shell. This script corresponds
to oe-init-build-env found in OpenEmbedded/Yocto, but it will additionally
update the `conf/bblayers.conf` file. It must be sourced in each shell that is
used to run builds.

After updating the layers and sourcing em-build-env, a bitbake command can be
executed. The following commands are used to build the EM SDK update bundle:

    ./em-update
    . ./em-build-env
    bitbake em-bundle-sdk

The Yocto build configuration can be adjusted in `conf/local.conf` in the
generated build directory or in custom layers.


## Configuration
The cloned layers are configured in the files `em-layers.conf` and
`local/em-layers.conf`. `local/em-layers.conf` does not exist by default and
can be used to add custom layers to the build. The `local` directory is
excluded from source control in the em-build repo itself.
If desired, `local` can be made into a separate git repository to track changes
of `local/em-layers.conf`.

An example `local/em-layers.conf` is given in the following:

    LAYERS += meta-custom

    meta-custom_repo           = ssh://git@git.example.com/meta-custom.git
    meta-custom_branch         = master
    # meta-custom_commit       =
    # meta-custom_subdirs      =

Each layer must be a git repository; the URL and branch that should be cloned
are configured in the `..._repo` and `..._branch` variables.

The `..._commit` variable defines a specific commit from the cloned branch that
should be checked out to allow creating a reproducible build environment. If
unset, the layer will be updated to the HEAD of the given branch on each run of
em-update.

The `..._subdirs` variable allows to provide a (space-separated) list of
subdirectories of the git repository that should be added to bblayers.conf. If
unset, the toplevel directory of the repository will be used.

For development purposes, it is also possible to add manually managed layer
directories under `layers/`. By adding such a layer to `local/em-layers.conf`,
but leaving the `..._repo` variable unset, `em-update` will simply ignore the
directory. `em-build-env` will add it (or the configured subdirs) to
`bblayers.conf`.

The `em-layers.conf` files follow standard Makefile syntax.

## Release
Typically, a release commit only updates the `em-layers.conf` file.
