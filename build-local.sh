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

if [[ "$1" == "chunked" ]]; then
    chunked='true'
else
    chunked='false'
fi

BB_BUILD_CHUNKED_OCI="$chunked" bluebuild build -T rpm-ostree -S cosign -R podman -v recipes/recipe.yml
