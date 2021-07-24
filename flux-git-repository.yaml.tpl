apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: ${ name }
  namespace: ${ namespace }
spec:
  interval: ${ reconcile_interval }
  url: ${ git_repo }
