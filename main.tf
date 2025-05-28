provider "github" {
  # env:GITHUB_TOKEN
  # token = ""
  # this is the default user under which all unqualified references resolve
  # env:GITHUB_OWNER
  # owner = ""
}

variable "the_repo" {
  type    = string
  description = "the **UNQUALIFIED** name of the repository to create environments for"
  default = "repo1"
}

variable "environments" {
  type = list(string)
  default = [
    "dev",
    "staging",
    "prod",
    "demo",
  ]
}

variable "env_to_branch" {
  type = map(string)
  default = {
    dev     = "main"
    staging = "staging"
    prod    = "prod"
    demo    = "demo"
  }
}

variable "env_to_eks_arn_mapping" {
  type = map(string)
  default = {
    dev = "arn:aws:eks:us-west-2:000011112222:cluster/dev-eks"
    # yes, purposefully the same
    staging = "arn:aws:eks:us-west-2:000011112222:cluster/dev-eks"
    prod    = "arn:aws:eks:us-west-2:444455556666:cluster/prod-us-west-2"
    demo    = "arn:aws:eks:us-west-2:666677778888:cluster/demo-us-west-2"
  }
}

data "github_user" "current" {
  # blank username will use the authenticated user
  username = ""
}

resource "github_repository_environment" "env" {
  for_each    = toset(var.environments)
  repository  = var.the_repo
  environment = "env/${each.key}"
  # dunno what the use case is for this
  # wait_timer  = 1440  # minutes
  reviewers {
    users = [data.github_user.current.id]
  }
  deployment_branch_policy {
    # turns out these have to DIFFER
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_actions_environment_variable" "eks_arn" {
  for_each   = toset(var.environments)
  repository    = var.the_repo
  # depend on the environment being created first
  environment   = github_repository_environment.env[each.key].environment
  variable_name = "EKS_ARN"
  value         = var.env_to_eks_arn_mapping[each.key]
}


resource "github_repository_environment_deployment_policy" "branch_policy" {
  for_each       = toset(var.environments)
  repository     = var.the_repo
  environment    = github_repository_environment.env[each.key].environment
  branch_pattern = var.env_to_branch[each.key]
}
