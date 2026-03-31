output "vpc_id" {
  value       = local.enabled ? aws_vpc.this[0].id : ""
  description = "The ID of the VPC."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "The IDs of the public subnets."
}
