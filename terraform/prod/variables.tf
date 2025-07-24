# In this file put the variables related to the deployment
variable "bucket_name" {
    type = string
    default = "fullstack-hadi-prod"
}

variable "tags"{
    type = map(string)
    default = {
        Environment = "prod"
        Project = "FullStack"
        Managed_by = "Terraform"
    }
}
