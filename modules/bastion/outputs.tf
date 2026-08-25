output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.bastion.id
}
output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.bastion.arn
}
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.bastion.id
}
output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.bastion.arn
}
output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.bastion.name
}
output "ssm_instance_id_parameter" {
  description = "SSM parameter name containing the instance ID"
  value       = aws_ssm_parameter.bastion_instance_id.name
}
