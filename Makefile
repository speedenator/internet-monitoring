#!/usr/bin/env make

# You came in that thing? You're braver than I thought!

DEPLOYS        = deploys
REGION        ?= docker-desktop
ENVIRONMENT   ?= dev
STACK          = $(REGION)-$(ENVIRONMENT)
NOW            = `date +'%Y-%m-%dT%H%M'`

PBCOPY		= pbcopy # change to "clip" for Windows

PROJECTS       = projects

.PHONY: help docker

# don't delete intermediate files
.SECONDARY:

PROVIDER_DIR = provider

STACK ?= dev

######################################################################
#
# autogen dependencies
# ripped off from: https://gist.github.com/eikevons/b935b52d885c7509572e42477e9a7569

help:
	@echo
	@echo '  check                                   --- make sure you have all build executables'
	@echo
	@echo '  provider/<name>/<env>/all.provisioned   --- provision Airflow to <name> in env <env>'
	@echo '  clean                                   --- remove all build stamps'
	@echo


check:
	@command -v kubectl || (echo "kubectl not found, please install it via brew install kubernetes-cli" && false)
	@command -v helm || (echo "helm not found, please install it via brew install kubernetes-helm" && false)

define markProvisioned
@rm -f $(basename $1).deleted
@touch $(basename $1).provisioned
endef

define markDeleted
@rm -f $(basename $1).provisioned
@touch $(basename $1).deleted
endef


######################################################################

DOCKER_LOG = $(DEPLOYS)/docker.log

$(DEPLOYS):
	@mkdir -p $(DEPLOYS)

######################################################################

clean:
	@rm $(DEPLOYS)/*



######################################################################
#
# kubernetes 
#

# to set a different KUBECONTEXT, uncomment and fix the below
KUBECONTEXT = # --kubeconfig=<path_to_kubeconfig>

KUBECTL = kubectl $(KUBECONTEXT)


dashboard-services-$(STACK): $(DEPLOYS)/$(STACK)/dashboard-services-$(STACK).provisioned
dashboard: $(DEPLOYS)/$(STACK)/dashboard-services-$(STACK).provisioned

$(DEPLOYS)/$(STACK):
	mkdir -p $(DEPLOYS)/$(STACK)

$(DEPLOYS)/$(STACK)/dashboard-services-$(STACK).provisioned: $(DEPLOYS)/$(STACK)
# main dashboard
	$(KUBECTL) apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
	@rm -f $(basename $@).deleted
	@touch $(basename $@).provisioned

token:	dashboard-token
dashboard-token: dashboard-token-$(STACK)

dashboard-token-$(STACK):
	@echo
	@echo "Please use the following token in the Web UI:"
	@echo "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy"
	@echo "(automatically copied to clipboard if on osx!)"
	@echo ""
	@echo "Remember to start the proxy via: kubectl proxy"
	@echo ""
	$(KUBECTL) -n kube-system describe secret $$($(KUBECTL) -n kube-system get secret | grep eks-admin | awk '{print $$1}') | grep token: | awk '{print $$2}'
# for osx, automatically put it in the buffer. 
	@$(KUBECTL) -n kube-system describe secret $$($(KUBECTL) -n kube-system get secret | grep eks-admin | awk '{print $$1}') | grep token: | awk '{print $$2}' | $PBCOPY

dashboard-all: dashboard-$(STACK)

dashboard-$(STACK): dashboard-services-$(STACK) dashboard-token-$(STACK)

proxy: proxy-$(STACK)

proxy-$(STACK):
	$(KUBECTL) proxy

