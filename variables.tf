variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type    = string
  default = "cassidynelemans.com"
}

variable "role_name" {
  description = "Name for the Lambda role."
  default     = "contact-form"
}

variable "function_name" {
  description = "Name for the Lambda function."
  default     = "contact-form"
}

variable "billing_tag" {
  description = "Name for a tag to keep track of resource for billing."
  default     = "cassidynelemans.com"
}

variable "api_gateway_name" {
  description = "Name for your API gateway."
  default     = "contact-form"
}

variable "api_gateway_description" {
  description = "Description of your API gateway."
  default     = "API gateway for contact form"
}
