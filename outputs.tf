output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_name" {
  description = "The name of the created VPC"
  value       = aws_vpc.main.tags["Name"]
}
