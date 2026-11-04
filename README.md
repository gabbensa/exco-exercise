# DevOps Exercise — Web service to local K8s, the GitOps way

## Plan
1. Flask web service (HTML: message, version, pod name) + /healthz
2. Dockerfile (non-root user), build & test locally
3. Terraform: kind cluster (1 control-plane + 2 workers) + Argo CD + ingress-nginx
4. K8s manifests in this repo, synced by Argo CD (2 replicas, probes, resources)
5. App exposed via Ingress, opens in the browser
6. CI/CD: GitHub Actions -> GHCR -> image tag bumped in git -> Argo rolls out

## Tools chosen
- kind: lightweight local K8s, has a Terraform provider
- Flask: minimal web service
- Argo CD: GitOps sync ; ingress-nginx: ingress controller
- AI: Claude (session kept open), prompts logged in ai-prompts.md

## Progress log
- [x] Plan written
