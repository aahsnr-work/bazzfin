# Developer conveniences for building/testing the image locally with the
# BlueBuild CLI: https://blue-build.org/how-to/local/
# Install it first (see the CLI README for options), e.g.:
#   cargo install --locked blue-build

set shell := ["/usr/bin/bash", "-cu"]

# Print/save the Containerfile that would be generated from the recipe
@generate recipe="recipe.yml":
    bluebuild generate recipes/{{ recipe }} -o Containerfile

# Build the image locally with podman/buildah
@build recipe="recipe.yml":
    bluebuild build recipes/{{ recipe }}

# Validate recipes/recipe.yml against the BlueBuild schema
@validate recipe="recipe.yml":
    bluebuild validate recipes/{{ recipe }}

# Build, then rebase this machine onto the local build (rpm-ostree/bootc)
@switch recipe="recipe.yml":
    bluebuild switch recipes/{{ recipe }}

# Shellcheck all bash scripts. (build-initramfs.sh was removed here --
# initramfs regeneration is now handled by the `initramfs` module in
# recipe.yml instead of a hand-rolled script.) Restricted to *.sh so a
# future non-script file dropped into files/scripts/ doesn't get lint-checked.
@lint:
    find files/scripts -type f -name '*.sh' -exec shellcheck {} +
