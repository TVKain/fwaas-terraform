terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

provider "openstack" {
  cloud = "openstack"  
}

resource "openstack_identity_project_v3" "fwaas_test" {
  name        = "fwaas_test"
}

resource "openstack_networking_quota_v2" "quota" {
  project_id = openstack_identity_project_v3.fwaas_test.id 
  port = 1000 
  router = 1000
  network = 1000 
  subnet = 1000 

}

resource "openstack_identity_role_assignment_v3" "admin_fwaas" {
  user_id    = var.admin_user 
  project_id = openstack_identity_project_v3.fwaas_test.id
  role_id    = var.admin_role
}

resource "openstack_networking_network_v2" "vlan" {
  count = var.number_of_vlans

  name         = "vlan-${2000 + count.index}"
  admin_state_up = true
  segments {
    physical_network = "physnet2" 
    segmentation_id = 2000 + count.index
    network_type = "vlan"
  }
  tenant_id = openstack_identity_project_v3.fwaas_test.id
}

resource "openstack_networking_subnet_v2" "vlan_subnet" {
  count = var.number_of_vlans

  network_id     = openstack_networking_network_v2.vlan[count.index].id
  cidr           = "192.168.${count.index}.0/24"
  ip_version     = 4
  name           = "subnet-${2000 + count.index}"
  gateway_ip     = "192.168.${count.index}.1"
}

resource "openstack_networking_router_v2" "router" {
  count = var.number_of_vlans

  name           = "router-${count.index + 1}"
  admin_state_up = true
  external_network_id = var.external_network
  tenant_id = openstack_identity_project_v3.fwaas_test.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  count = var.number_of_vlans

  router_id = openstack_networking_router_v2.router[count.index].id
  subnet_id = openstack_networking_subnet_v2.vlan_subnet[count.index].id
}

resource "openstack_fw_rule_v2" "rule" {
    count = var.number_of_rules

    name = "firewall-rule-${count.index + 1}" 
    action = "allow" 
    protocol = "tcp"
    destination_port = "${count.index + 1}"
    enabled = "true"
    project_id = openstack_identity_project_v3.fwaas_test.id
}

resource "openstack_fw_policy_v2" "ingress_policy" {
    count = var.number_of_vlans 
    name = "ingress-policy-${count.index + 1}"
    rules = flatten([
        for rule in openstack_fw_rule_v2.rule : rule.id
    ])
    project_id = openstack_identity_project_v3.fwaas_test.id
}

resource "openstack_fw_policy_v2" "egress_policy" {
    count = var.number_of_vlans 
    name = "egress-policy-${count.index + 1}"
    
    rules = flatten([
        for rule in openstack_fw_rule_v2.rule : rule.id
    ])
    project_id = openstack_identity_project_v3.fwaas_test.id
}

resource "openstack_fw_group_v2" "firewall_group" {
    count = var.number_of_vlans 
    name = "firewall-group-${count.index + 1}" 

    ingress_firewall_policy_id = openstack_fw_policy_v2.ingress_policy[count.index].id
    egress_firewall_policy_id = openstack_fw_policy_v2.egress_policy[count.index].id

    ports = [openstack_networking_router_interface_v2.router_interface[count.index].port_id]

    project_id = openstack_identity_project_v3.fwaas_test.id
}