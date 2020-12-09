#!/usr/bin/env bash
set -o pipefail

readonly secret_header=$(cat <<-'END_HEREDOC'
apiVersion: v1
kind: Secret
type: Opaque
metadata:
END_HEREDOC
)

readonly systype=$(uname -s)

function fail {
    printf "ERROR: %s\n" "$@"
    exit 1
}

function build_secret {
    local src=$1
    local ns=$2
    local secret_name=$3
    local secret_basename=$(basename $src)

    # The Darwin/BSD version of base64 doesn't support the "-w" option, but it
    # turns out that the "-w 0" behavior is the default behavior for BSD.
    if [ $systype == "Darwin" ]; then
        base64_cmd="base64"
    else
        base64_cmd="base64 -w 0"
    fi
    local enc_secret=$(cat $src | $base64_cmd)

    [ -z $secret_name ] && secret_name=$(basename $src | sed s/\\./\-/g)

    echo "$secret_header"
    printf "  name: %s\n" $secret_name
    printf "  namespace: %s\n" $ns
    printf "data:\n"
    printf "  %s: %s\n" $secret_basename $enc_secret
}

[ -z $1 ] || [ -z $2 ] && fail "usage: build-secret <secret> <namespace> [secret-name]"

[ ! -f $1 ] && fail "$1 does not exist"

build_secret $1 $2 $3

exit 0
