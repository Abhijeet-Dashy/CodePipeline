variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "github_repo" {
  description = "The GitHub repository in 'owner/repo' format."
  type        = string
  # Replace with your GitHub username and repo name
  default     = "Abhijeet-Dashy/CodePipeline"
}

variable "github_branch" {
  description = "The branch to trigger the pipeline from."
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "The ARN of the AWS CodeStar connection to GitHub."
  type        = string
  default     = "arn:aws:codeconnections:ap-south-1:427212782605:connection/bf58e7a3-5e01-4ca2-a4af-ec45f1bb95ac"
  # You will create this manually in the AWS Console and paste the ARN here.
}