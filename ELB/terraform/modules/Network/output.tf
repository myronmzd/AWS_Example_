output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id  # ✅ Directly reference the local resource
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.main.id  # ✅ Directly reference the local resource
}