locals {
  /*
  Role names should not use _ but use - instead.
  */
  env_preset = {
    all = {
      test    = {}
      staging = {}
      rc      = {}
      prod    = {}
      qdaily  = {}
    }
    all_except_qdaily = {
      test    = {}
      staging = {}
      rc      = {}
      prod    = {}
    }
    all_except_rc = {
      test    = {}
      staging = {}
      qdaily  = {}
      prod    = {}
    }
  }
  yaml-roles = yamldecode(file(var.roles_yaml))
  roles = try(local.yaml-roles.roles,{})
  default_role = {
    description = "Managed by Automated Terraform"
  }
  roles_processed = {
  # merge(
    // normal roles
    # {
    #   for role, config in local.roles :
    #   role => merge(local.default_role, config, 
    #     { 
    #         role = join("_", compact([
    #             config.assumeRole != "" ? config.assumeRole : "",
    #             role
    #         ]))
    #         trust = try(config.trust, file("policies/${config.assumeRole}-role.json"), file("policies/default-role.json"))
    #     }
    #   )
    #   if !contains(keys(config), "env_config")
    # },
    // roles with env overrides
    # {
      for data in flatten(concat([
        for role, config in local.roles : [
          # type(config.env_config) == "string" ? 
          for env, env_config in try(local.env_preset[config.env_config], config.env_config, { "" = {}}) : 
            merge(local.default_role, config, env_config, { 
                role = join("_", compact([
                    config.assumeRole != "" ? config.assumeRole : "",
                    role,
                    env
                ]))
                trust = try(config.trust, file("policies/${config.assumeRole}-role.json"), file("policies/default-role.json"))
                policy = try(config.permissions, null)
            })
        ]
        # if contains(keys(config), "env_config")
      ])) : data.role => data
    }
  # )
  custom_policies = { for role, config in local.roles_processed: 
    role => {
      role = aws_iam_role.role[role].id
      policy = config.permissions 
    }
    if config.permissions != null
  }
  attach_policies_to_roles = merge(
    { 
      for data in flatten(
        [ for role, config in local.roles : concat(
          [ for policy in config.policies : {
            id     = format("%s/%s", role, policy)
            role   = aws_iam_role.role[role].id
            policy = format("arn:aws:iam::%s:policy/%s", var.aws_account_id, policy)
          }],
          [ for policy in config.aws_managed_policies : {
            id     = format("%s/%s", role, basename(policy))
            role   = aws_iam_role.role[role].id
            policy = policy
          }]
        )]
      ) : data.id => data
    }
  )
}

resource "aws_iam_role" "role" {
  for_each           = local.roles_processed
  name               = each.value.role
  description        = each.value.description
  assume_role_policy = each.value.trust
  tags               = var.tags
}

# This is the custom inline policies that we don't think we will be reusing.
resource "aws_iam_role_policy" "policy_custom" {
  for_each = local.custom_policies
  name     = each.key
  role     = each.value.role
  policy   = each.value.policy
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each   = local.attach_policies_to_roles
  role       = each.value.role
  policy_arn = each.value.policy
}