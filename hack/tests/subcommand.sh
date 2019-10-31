#!/usr/bin/env bash
source hack/lib/test_lib.sh

set -ex

if [ -z "$KUBECONFIG" ]; then
  KUBECONFIG=$HOME/.kube/config
fi

pushd test/test-framework
# test framework with defaults
operator-sdk test local ./test/e2e

# test operator-sdk test flags
operator-sdk test local ./test/e2e --global-manifest deploy/crds/cache.example.com_memcacheds_crd.yaml --namespaced-manifest deploy/namespace-init.yaml --go-test-flags "-parallel 1" --kubeconfig $KUBECONFIG --image=quay.io/coreos/operator-sdk-dev:test-framework-operator-runtime

# we use the test-memcached namespace for all future tests, so we only need to set this trap once
kubectl create namespace test-memcached
trap_add 'kubectl delete namespace test-memcached || true' EXIT
operator-sdk test local ./test/e2e --namespace=test-memcached
kubectl delete namespace test-memcached

# test operator in up local mode
kubectl create namespace test-memcached
operator-sdk test local ./test/e2e --up-local --namespace=test-memcached
kubectl delete namespace test-memcached

# test operator in up local mode with kubeconfig
kubectl create namespace test-memcached
operator-sdk test local ./test/e2e --up-local --namespace=test-memcached --kubeconfig $KUBECONFIG
kubectl delete namespace test-memcached

# test operator in up local mode with namespace set to ""
# --namespace="" is allowed in local mode only when --no-setup is set
kubectl create namespace test-memcached
kubectl create -f deploy/crds/cache.example.com_memcacheds_crd.yaml
# this runs after the popd at the end (trap_add popd), so it needs the path from the project root
trap_add 'kubectl delete --ignore-not-found test/test-framework/deploy/crds/cache.example.com_memcacheds_crd.yaml' EXIT
kubectl create -f deploy/crds/cache.example.com_memcachedrs_crd.yaml
# this runs after the popd at the end (trap_add popd), so it needs the path from the project root
trap_add 'kubectl delete --ignore-not-found test/test-framework/deploy/crds/cache.example.com_memcachedrs_crd.yaml' EXIT
operator-sdk test local ./test/e2e --up-local --namespace="" --no-setup --debug
kubectl delete -f deploy/crds/cache.example.com_memcacheds_crd.yaml
kubectl delete -f deploy/crds/cache.example.com_memcachedrs_crd.yaml
kubectl delete namespace test-memcached

# test operator in no-setup mode
kubectl create namespace test-memcached
kubectl create -f deploy/crds/cache.example.com_memcacheds_crd.yaml
# this runs after the popd at the end, so it needs the path from the project root
trap_add 'kubectl delete --ignore-not-found -f test/test-framework/deploy/crds/cache.example.com_memcacheds_crd.yaml' EXIT
kubectl create -f deploy/crds/cache.example.com_memcachedrs_crd.yaml
# this runs after the popd at the end, so it needs the path from the project root
trap_add 'kubectl delete --ignore-not-found -f test/test-framework/deploy/crds/cache.example.com_memcachedrs_crd.yaml' EXIT
kubectl create -f deploy/service_account.yaml --namespace test-memcached
kubectl create -f deploy/role.yaml --namespace test-memcached
kubectl create -f deploy/role_binding.yaml --namespace test-memcached
kubectl create -f deploy/operator.yaml --namespace test-memcached
operator-sdk test local ./test/e2e --namespace=test-memcached --no-setup
kubectl delete namespace test-memcached
popd
