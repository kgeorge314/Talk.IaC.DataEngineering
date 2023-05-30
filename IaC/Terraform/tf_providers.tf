terraform {
  required_version = ">=1.4.6"

  # Backend details will be passed via environment variables so that sensitive data doesn't touch disk
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.57.0"
    }
  }
}
