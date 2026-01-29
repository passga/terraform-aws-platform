#!/bin/bash

set -euo pipefail


#parse_options() {
#	for arg in "$@"
#	do
#		case ${arg} in
#	    	"awake-server")
#	    		CMD=awake-server
#	    	;;
#	    	"create-infra")
#	    		CMD=create-infra
#	    	;;
#	      "deploy-rke")
#        	CMD=deploy-rke
#       	;;
#        "destroy-infra")
#	    		CMD=destroy-infra
#	    	;;
#	      "destroy-rke")
#     	  		CMD=destroy-rke
#     	  ;;
#	    	"setup")
#            CMD=setup
#	    	;;
#	   	"setup")
#                 CMD=setup
#     	    	;;
#	    esac
#	done
#
#}
#
#
#parse_options $*

SAURON_TAG_NAME="${SAURON_TAG_NAME:-bonitasoft/sauron:latest}"
RANCHER_PATH="${RANCHER_PATH:-$PWD/rancher/}"
TERRAFORM_PATH="${TERRAFORM_PATH:-$PWD/../../terraform/}"
HELM_CHARTS_PATH="${HELM_CHARTS:-$PWD/../../charts}"
AWS_FILES_PATH="${AWS_FILES_PATH:-$PWD}"
KUBERNATES_CONFIG_PATH="${KUBERNATES_CONFIG_PATH:-$PWD/../../terraform/}"

run_cmd="docker run --rm  -i -t  -v ${HELM_CHARTS_PATH}:/opt/file/charts -v ${RANCHER_PATH}:/root/.rancher/ -v ${TERRAFORM_PATH}:/opt/terraform/ -v ${AWS_FILES_PATH}/aws/:/root/.aws/  ${SAURON_TAG_NAME} $@"
echo "Running command: '$run_cmd'"
eval "$run_cmd"

