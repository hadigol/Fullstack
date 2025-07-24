# In this file put the variables related to the deployment
variable "bucket_name" {
    type = string
    default = "fullstack-hadi-stage"
}

variable "tags"{
    type = map(string)
    default = {
        Environment = "stage"
        Project = "FullStack"
        Managed_by = "Terraform"
    }
}
