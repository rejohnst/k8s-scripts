#!/usr/bin/env bash
set -o pipefail

readonly kustomize_header=$(cat <<-'END_HEREDOC'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
END_HEREDOC
)

function fail {
    printf "ERROR: %s\n" "$@"
    exit 1
}

function build_kustomize {
    local dest_dir=$1

    local tmpfile=$(mktemp /tmp/kustomize.XXX)
    [ $? != 0 ] && fail "mktemp failed"

    [ -f $dest_dir/kustomization.yaml ] && rm $dest_dir/kustomization.yaml
    run_cmd touch /tmp/kustomization.yaml

    echo "$kustomize_header" >> $tmpfile
    for yaml in `(cd $dest_dir; ls *.yaml)`; do
        echo "  - $yaml" >> $tmpfile
    done
    
    run_cmd mv $tmpfile $dest_dir/kustomization.yaml
}

function run_cmd {
    local cmd="$@"
    local status

    `$cmd > /dev/null 2>&1`
    status=$?

    [ $status != 0 ] && fail "Command exited with status $status: $cmd"
}

[ -z $1 ] && fail "usage: build-kustomization <yaml-dir>"

build_kustomize $1

exit 0
