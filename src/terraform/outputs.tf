output "url" {
  description = "Base URL for Resourcspace."
  value       = "https://${var.service_names[0]}.[LICENCEPLATE]-${var.target_env}.nimbus.cloud.gov.bc.ca/"
}

output "db" {
  description = "Aurora database dns name"
  value       = aws_efs_file_system.efs_filestore.dns_name
}