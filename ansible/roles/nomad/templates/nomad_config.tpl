datacenter = "dc1"
data_dir   = "/opt/nomad"
advertise {
  http = "{{ '{{ GetInterfaceIP \\\"eth0\\\" }}' }}"
  rpc  = "{{ '{{ GetInterfaceIP \\\"eth0\\\" }}' }}"
  serf = "{{ '{{ GetInterfaceIP \\\"eth0\\\" }}' }}"
}

{% if nomad_server_node == 'true' %}
server {
  enabled          = true
  bootstrap_expect = 1
}
{% endif %}

vault {
  enabled = true
  address = "http://192.168.7.128:8200"
{% if nomad_server_node == 'true' %}
  token = "hvs.RpKZtAiUyIWrA8ffaU6RXMrS"
{% endif %}
}

plugin "docker" {
  config {
    allow_privileged = true
    allow_caps = ["all"]
    volumes {
      enabled = true
    }
  }
}

client {
  enabled = true
}
