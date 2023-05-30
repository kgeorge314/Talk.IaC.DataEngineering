variable "location" {
  description = "Azure region where resources will be located. Possible values are : 'North Europe', 'Central US' , 'East Us' and 'North Central US'"
  type        = string
  validation {
    condition     = can(regex("^(northeurope|centralus|northcentralus|westus|eastus)$", lower(replace(var.location, " ", ""))))
    error_message = "The location can only be North Europe, Central US, North Central US, West US, East US."
  }
  default = "northeurope"
}

variable "environment" {
  description = "The type of environment. Possible values are : 'infra', 'sandbox', 'dev', 'pre', 'staging', 'prod' , 'pre'."
  type        = string
  validation {
    condition     = can(regex("^(infra|sandbox|dev|staging|pre|prod)$", var.environment))
    error_message = "The environment can only be infra, sandbox, dev, staging, pre, prod."
  }
  default = "sandbox"
}