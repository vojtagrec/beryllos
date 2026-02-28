#!/usr/bin/env bash

chunked='false'

case "$1" in
    'chunked')
        chunked='true'
        ;;
    'clear')
        echo 'Clearing existing local builds...'
        readarray -t images < <(podman images -f reference=localhost/beryllos -q)
        podman rmi -f "${images[@]}"
        echo 'Done.'
        exit
        ;;
esac

BB_BUILD_CHUNKED_OCI="$chunked" BB_BUILD_RECHUNK_CLEAR_PLAN=true bluebuild build -T rpm-ostree -S cosign -R podman -B buildah -c zstd -v recipes/recipe.yml
