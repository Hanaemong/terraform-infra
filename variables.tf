# variables.tf
variable "certificate_arn" {
  description = "The ARN of the SSL certificate"
  type        = string
  default     = "arn:aws:acm:ap-northeast-2:891376910560:certificate/7ef53b32-af7a-4c3a-9a53-31777fe98742"
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  type        = string
  default     = "Z04195123RHMGAK203ML6"
}
