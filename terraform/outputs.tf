output "instance_name" {
  value = random_pet.instances_name.id
}

output "DB_name" {
  value = random_pet.DB_NAME.id
}

output "S3_bucket_name" {
  value = random_pet.upload_bucket_name.id
}

output "target_group_name" {
  value = random_pet.target_group_name.id
}