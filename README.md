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
- [x] Flask service written (HTML page + /healthz)
- [x] Non-root Dockerfile, image built and tested locally in the browser
- [x] Terraform: kind cluster (1 control-plane + 2 workers), Argo CD, ingress-nginx

## One decision and why
Installed Argo CD and ingress-nginx from the official manifests via Terraform local-exec,
instead of the Helm provider: simpler, reproducible, and I understand every command.
In production I would manage them with the Helm provider and pinned chart versions.

## Where the AI was wrong (and how I noticed)
- It suggested pre-loading the Argo CD image with `kind load` — failed on a multi-node
  cluster with a multi-platform image (ctr digest error in the terraform output). Dropped it.
- It gave the ingress-nginx manifest URL on the `main` branch and with the wrong GitHub org —
  both 404s in the apply output. Fixed by pointing to kubernetes/ingress-nginx at a pinned
  release tag (controller-v1.15.1). Lesson: pin versions, never track main.
- The Argo CD install failed client-side on the huge ApplicationSet CRD ("annotations too long");
  switched to `kubectl apply --server-side`.
- [x] Argo CD syncs k8s/ from this repo (automated, selfHeal, prune)
- [x] App reachable in the browser at http://localhost via ingress-nginx

## Troubleshooting worth noting
The ingress controller first scheduled on a worker node, while the host port
mapping (80/443) lives on the control-plane: connections were reset. Diagnosed
with `kubectl get pods -o wide` + a direct port-forward test, fixed by patching
the controller deployment with a nodeSelector (ingress-ready=true) and a
control-plane toleration. In production this pinning would live in the IaC,
not in a manual patch.
- [x] CI/CD: GitHub Actions builds and pushes the image to GHCR (commit SHA tag)

## Troubleshooting: GHCR push denied
The first pushes failed with `denied` on the final manifest push. Checked in
order: workflow token permissions (packages: write), the repo's Actions
"Read and write" setting, a possible name hold after deleting a half-created
package. Root cause found in the package's "Manage Actions access": the repo
was linked with the Admin role, which (counter-intuitively) does not grant
push to the Actions token — switching the role to Write fixed it.
