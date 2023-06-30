#output "web_instance_ip" {
#    value = aws_instance.web[count.index].public_ip
#}
output "CustomTG" {
  value       = aws_lb_target_group.CustomTG.id
  description = "This is Target Group id."
}
output "elb_sg" {
  value       = aws_security_group.sg.id
  description = "This is Security Group ID."
}


