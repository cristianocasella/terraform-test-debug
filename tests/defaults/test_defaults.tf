terraform {
  required_providers {
    # Because we're currently using a built-in provider as
    # a substitute for dedicated Terraform language syntax
    # for now, test suite modules must always declare a
    # dependency on this provider. This provider is only
    # available when running tests, so you shouldn't use it
    # in non-test modules.
    test = {
      source = "terraform.io/builtin/test"
    }

    # This example also uses the "http" data source to
    # verify the behavior of the hypothetical running
    # service, so we should declare that too.
    http = {
      source = "hashicorp/http"
    }
  }
}

module "main" {
  # source is always ../.. for test suite configurations,
  # because they are placed two subdirectories deep under
  # the main module directory.
  source = "../.."

  region                           = "ca-central-1"

  # This test suite is aiming to test the "defaults" for
  # this module, so it doesn't set any input variables
  # and just lets their default values be selected instead.
}

# As with all Terraform modules, we can use local values
# to do any necessary post-processing of the results from
# the module in preparation for writing test assertions.
locals {
  # This expression also serves as an implicit assertion
  # that the base URL uses URL syntax; the test suite
  # will fail if this function fails.
  dummy_vpc = module.main.k8s_cluster_vpc
}

# The special test_assertions resource type, which belongs
# to the test provider we required above, is a temporary
# syntax for writing out explicit test assertions.
resource "test_assertions" "dummy_vpc" {
  # "component" serves as a unique identifier for this
  # particular set of assertions in the test results.
  component = "network"

  # equal and check blocks serve as the test assertions.
  # the labels on these blocks are unique identifiers for
  # the assertions, to allow more easily tracking changes
  # in success between runs.

  # VPC test
  equal "cidr_block" {
    description = "default cidr is 10.0.0.0/16"
    got         = local.dummy_vpc.cidr_block
    want        = "10.0.0.0/16"
  }

  equal "enable_dns_hostnames" {
    description = "dns hostnames should be enabled"
    got         = local.dummy_vpc.enable_dns_hostnames
    want        = true
  }

  # Subnet test
  equal "enable_dns_support" {
    description = "dns support should be enabled"
    got         = local.dummy_vpc.enable_dns_support
    want        = true
  }

  equal "ipv6" {
    description = "ipv6 should not be used"
    got         = local.dummy_vpc.assign_generated_ipv6_cidr_block
    want        = false 
  }

  # Objects existing test
  check "routing_table" {
    description = "default routing table should exists"
    condition   = can(regex("^rtb-[a-z0-9]+$", local.dummy_vpc.default_route_table_id))
  }

  check "security_group" {
    description = "default security group should exists"
    condition   = can(regex("^sg-[a-z0-9]+$", local.dummy_vpc.default_security_group_id))
  }

  check "network_acl" {
    description = "default network acl should exists"
    condition   = can(regex("^acl-[a-z0-9]+$", local.dummy_vpc.default_network_acl_id))
  }
}
