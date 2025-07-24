# In this file put the variables related to the deployment
variable "bucket_name" {
    type = string
    default = "fullstack-hadi-dev"
}

variable "tags"{
    type = map(string)
    default = {
        Environment = "dev"
        Project = "FullStack"
        Managed_by = "Terraform"
    }
}
