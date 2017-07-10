provider "opc" {
  user = "${var.user}"
  password = "${var.password}"
  identity_domain = "${var.domain}"
  endpoint = "${var.endpoint}"
}

resource "opc_compute_ssh_key" "ssh_key" {
  name = "ip-network-example-key"
  key = "${file(var.ssh_public_key)}"
  enabled = true
}

resource "opc_compute_ip_network" "ip-network-1" {
  name = "IPNetwork_1"
  description = "Example IP Network 1"
  ip_address_prefix = "192.168.2.0/24"
  ip_network_exchange = "${opc_compute_ip_network_exchange.test-ip-network-exchange.name}"
}

resource "opc_compute_ip_network" "ip-network-2" {
  name = "IPNetwork_2"
  description = "Example IP Network 2"
  ip_address_prefix = "192.168.3.0/24"
  ip_network_exchange = "${opc_compute_ip_network_exchange.test-ip-network-exchange.name}"
}

resource "opc_compute_ip_network_exchange" "test-ip-network-exchange" {
  name = "IPExchange"
  description = "IP Network Exchange"
}

resource "opc_compute_vnic_set" "nat_set" {
  name         = "nat_vnic_set"
  description  = "NAT vnic set"
}

resource "opc_compute_route" "nat_route" {
  name              = "nat_route"
  description       = "NAT IP Network route"
  admin_distance    = 1
  ip_address_prefix = "0.0.0.0/0"
  next_hop_vnic_set = "${opc_compute_vnic_set.nat_set.name}"
}

resource "opc_compute_instance" "instance-1" {
	name = "app_01"
  hostname = "app01"
	label = "app_01"
	shape = "oc3"
	image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  networking_info {
    index = 0
    ip_network = "${opc_compute_ip_network.ip-network-1.name}"
    ip_address = "192.168.2.16"
  }
  ssh_keys = [ "${opc_compute_ssh_key.ssh_key.name}" ]
}

resource "opc_compute_instance" "instance-2" {
	name = "app_02"
  hostname = "app2"
	label = "app_02"
	shape = "oc3"
	image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  networking_info {
    index = 0
    ip_network = "${opc_compute_ip_network.ip-network-2.name}"
    ip_address = "192.168.3.11"
  }
  ssh_keys = [ "${opc_compute_ssh_key.ssh_key.name}" ]
}

resource "opc_compute_instance" "instance-3" {
	name = "nat_instance"
  hostname = "nat"
	label = "nat_instance"
	shape = "oc3"
	image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  networking_info {
    index = 0
    shared_network = true
    nat = [ "${opc_compute_ip_reservation.reservation1.name}" ]
  }
  networking_info {
    index = 1
    ip_network = "${opc_compute_ip_network.ip-network-2.name}"
    ip_address = "192.168.3.16"
    vnic_sets = ["${opc_compute_vnic_set.nat_set.name}"]
  }
  ssh_keys = [ "${opc_compute_ssh_key.ssh_key.name}" ]

  instance_attributes = <<JSON
  {
    "userdata":{
      "pre-bootstrap": {
        "failonerror": true,
        "script": [
          "sysctl -w net.ipv4.ip_forward=1",
          "systemctl start iptables",
          "iptables -t nat -A POSTROUTING -o eth0 -s 192.168.3.0/24 -j MASQUERADE",
          "iptables -t nat -A POSTROUTING -o eth0 -s 192.168.2.0/24 -j MASQUERADE",
          "iptables -D FORWARD 1"
        ]
      }
    }
  }
  JSON
}

resource "opc_compute_ip_reservation" "reservation1" {
	parent_pool = "/oracle/public/ippool"
	permanent = true
}


output "public_ip" {
  value = "${opc_compute_ip_reservation.reservation1.ip}"
}
