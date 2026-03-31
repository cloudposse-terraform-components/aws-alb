locals {
  enabled = module.this.enabled

  availability_zones = [
    for az in var.availability_zones : format("%s%s", data.aws_region.current.name, az)
  ]
}

data "aws_region" "current" {}

resource "aws_vpc" "this" {
  count = local.enabled ? 1 : 0

  cidr_block           = var.ipv4_primary_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = module.this.tags
}

resource "aws_internet_gateway" "this" {
  count = local.enabled ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = module.this.tags
}

resource "aws_subnet" "public" {
  count = local.enabled ? length(local.availability_zones) : 0

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = cidrsubnet(var.ipv4_primary_cidr_block, 8, count.index)
  availability_zone = local.availability_zones[count.index]

  tags = merge(module.this.tags, {
    (var.subnet_type_tag_key) = "public"
  })
}
