resource "kubectl_manifest" "application_argocd_cert_manager" {
  yaml_body = templatefile("${path.module}/templates/argocd-apps/cert-manager.yaml", {
    REPO_URL = local.repo_url
  })
  provisioner "local-exec" {
    command = "kubectl wait --for=jsonpath=.status.health.status=Healthy --timeout=300s -n argocd application/cert-manager"
    interpreter = ["/bin/bash", "-c"]
  }
}
