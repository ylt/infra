datacenter     = "dc1"
data_dir       = "/opt/consul"
bind_addr      = "{{ '{{ GetInterfaceIP \\\"eth0\\\" }}' }}"
advertise_addr = "{{ '{{ GetInterfaceIP \\\"eth0\\\" }}' }}"

{% if nomad_server_node == 'true' %}
client_addr    = "0.0.0.0"
ui               = true
server           = true
bootstrap_expect = 1
{% else %}
retry_join     = ["192.168.7.128"]
{% endif %}

ports {
  grpc = 8502
}
addresses {
}
connect {
  enabled = true
}
