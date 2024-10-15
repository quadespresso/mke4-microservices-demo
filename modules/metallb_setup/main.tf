resource "helm_release" "metallb" {
  create_namespace = true
  name             = "metallb"
  namespace        = "metallb-system"
  chart            = "metallb"
  repository       = "https://metallb.github.io/metallb"
  # version    = var.chart_version

  set {
    name  = "speaker.memberlist.mlBindPort"
    value = "17946"
  }

  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "kubectl_manifest" "ip_address_pool" {
  yaml_body = <<-YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - "${var.lb_address_range}" 
  YAML

  depends_on =[helm_release.metallb]
}

resource "kubectl_manifest" "l2_advertisement" {
  yaml_body = <<-YAML
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
  YAML

  depends_on =[helm_release.metallb]
}

resource "null_resource" "metallb_dependencies" {
  depends_on = [
    kubectl_manifest.ip_address_pool,
    kubectl_manifest.l2_advertisement
  ]
}
