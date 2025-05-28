terraform {
  required_providers {
    github = {
      source = "integrations/github"
      # https://registry.terraform.io/providers/integrations/github/6.6.0
      version = "~> 6.6.0"
    }
  }
}