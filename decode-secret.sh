#!/usr/bin/env bash

set -o pipefail

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly EXIT_USAGE=2

readonly usagemsg=$(cat <<-'END_HEREDOC'
usage: 
decode-secret.sh -h
or
decode-secret -f <yaml-file> -s <secret-name>
or
decode-secret -k <k8s-resource> -n <namespace> -s <secret-name>
END_HEREDOC
)

readonly yq_mesg=$(cat <<-'END_HEREDOC'
The yq utility is required by this tool.  You can install it by running:

GO111MODULE=on go get github.com/mikefarah/yq/v3

END_HEREDOC
)

function fail {
    printf "ERROR: %s\n" "$@"
    exit $EXIT_FAILURE
}

function usage {
    echo $usagemsg
    exit $EXIT_USAGE
}

while getopts "f:hk:n:s:" opt; do
    case ${opt} in
    f)
        yamlfile=$OPTARG
        ;;
    h)
        usage
        # not reached
        ;;
    k)
        k8s_rsrc=$OPTARG
        ;;
    n)
        ns=$OPTARG
        ;;
    s)
        secret=$OPTARG
        ;;
    :)
        usage
        # not reached
        ;;
    esac
done

[[ -n $yamlfile ]] && [[ -n $k8s_rsrc ]] && fail "-f and -k are mutually exclusive"
[[ -z $yamlfile ]] && [[ -z $k8s_rsrc ]] && fail "One of -f or -k are required"
[[ -n $k8s_rsrc ]] && [[ -z $ns ]] && fail "-n option is required when specifying -k"
[[ -z $secret ]] && fail "-s option is required"

which yq > /dev/null
[[ $? != 0 ]] && fail $yq_mesg

which kubectl > /dev/null
[[ $? != 0 ]] && fail "kubectl is required if -k is specified"

if [[ -n $yamlfile ]]; then
    yqarg="data[$secret]"
    yq r $yamlfile $yqarg | base64 -d
else
    secret=$(echo $secret | sed 's/\./\\./g')
    jsonpath="{.data.$secret}"
    kubectl get secret $k8s_rsrc -n $ns -o jsonpath=$jsonpath | base64 -d
fi

exit $EXIT_SUCCESS
