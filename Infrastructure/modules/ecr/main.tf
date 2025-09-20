resource "aws_ecr_repository" "ecr_repository" {
  name = var.name
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
   repository =  aws_ecr_repository.ecr_repository.id
  policy = jsonencode({
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire old images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": var.max_image_number
      },
      "action": {
        "type": "expire"
      }
    }
  ]
 })
}
