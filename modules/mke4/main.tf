locals {
  k0s_cluster_config_file = "${path.root}/k0s_cluster_config.yaml"
  mkectl_init_file        = "${path.root}/mkectl_init.yaml"
  mke4_config_file        = "${path.root}/mke4.yaml"
}

resource "null_resource" "mkectl_init" {
  provisioner "local-exec" {
    command = "mkectl init > ${local.mkectl_init_file}"
  }
  triggers = {
    always_run = timestamp()
  }
}

# Write the contents of 'var.k0s_cluster_config' to 'k0s_cluster_config.yaml'
resource "local_file" "k0s_cluster_config" {
  filename = local.k0s_cluster_config_file
  content  = var.k0s_cluster_config
}

# Create Python script to merge 2 YAML files
resource "local_file" "merge_yaml_script" {
  depends_on = [null_resource.mkectl_init, local_file.k0s_cluster_config]
  filename   = "${path.root}/merge_yaml_files.py"

  content = <<EOT
import yaml

k0s_cluster_config_file = "${local.k0s_cluster_config_file}"
mkectl_init_file = "${local.mkectl_init_file}"
mke4_config_file = "${local.mke4_config_file}"


# Custom representer to preserve multiline strings
# namely, a 'values' that uses '|'
def str_presenter(dumper, data):
    if "\n" in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


yaml.add_representer(str, str_presenter)

with open(k0s_cluster_config_file) as f:
    k0s_cluster_config = yaml.safe_load(f)

with open(mkectl_init_file) as f:
    mkectl_init = yaml.safe_load(f)

# Ensure that all controller nodes are also workers
for host in k0s_cluster_config["spec"]["hosts"]:
    if host["role"] == "controller":
        host["role"] = "controller+worker"
    host["ssh"]["port"] = 22

# mkectl_init["metadata"]["name"] = k0s_cluster_config["metadata"]["name"]
mkectl_init["spec"]["hosts"] = k0s_cluster_config["spec"]["hosts"]
mkectl_init["spec"]["k0s"] = k0s_cluster_config["spec"]["k0s"]

# Need to stick with 'dump' instead of 'safe_dump' to preserve multiline strings
with open(mke4_config_file, "w") as f:
    yaml.dump(mkectl_init, f, default_flow_style=False)

EOT
} # End of Python script creation

resource "null_resource" "merged_yaml_files" {
  depends_on = [local_file.k0s_cluster_config, local_file.merge_yaml_script]
  provisioner "local-exec" {
    command = "python3 ${path.root}/merge_yaml_files.py"
  }
  triggers = {
    always_run = timestamp()
  }
}


resource "null_resource" "run_mkectl_apply" {
  depends_on = [null_resource.merged_yaml_files]

  provisioner "local-exec" {
    command = <<EOT
      mkectl apply -f ${local.mke4_config_file}
      mv ~/.mke/mke.kubeconf ${path.root}/kubeconfig
      sleep 70
    EOT  
  }

  triggers = {
    first_task_ran = null_resource.merged_yaml_files.triggers.always_run
  }
}

