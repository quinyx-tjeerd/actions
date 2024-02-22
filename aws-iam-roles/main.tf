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

  roles = yamldecode(var.roles).roles
  default_role = {
    description = "Managed by Automated Terraform"
  }
  roles_processed = merge(
    // normal roles
    {
      for role, config in local.roles :
      role => merge(local.default_role, config, 
        { 
            role = join("_", compact([
                config.assumeRole != "" ? config.assumeRole : "",
                role
            ]))
            trust = try(config.trust, file("policies/${config.assumeRole}-role.json"), file("policies/default-role.json"))
        }
      )
      if !contains(keys(config), "env_config")
    },
    // roles with env overrides
    {
      for data in flatten(concat([
        for role, config in local.roles : [
          for env, env_config in (type(config.env_config) == "string" ? try(local.env_preset[config.env_config], null) : config.env_config) : 
            merge(config, env_config, { 
                role = join("_", compact([
                    config.assumeRole != "" ? config.assumeRole : "",
                    role,
                    env
                ]))
                trust = try(config.trust, file("policies/${config.assumeRole}-role.json"), file("policies/default-role.json"))
            })
        ]
        if contains(keys(config), "env_config")
      ])) : data.role => merge(local.default_role, data)
    }
  )

    attach_policies_to_roles = merge(
        { 
            for data in flatten([
                for role, config in local.roles : [
                    for policy in config.policies : {
                        id     = format("%s/%s", role, policy)
                        role   = aws_iam_role.role[role].id
                        policy = format("arn:aws:iam::%s:policy/%s", var.aws_account_id, policy)
                    }
                ]
            ]) : data.id => data
        },
        { 
            for data in flatten([
                for role, config in local.roles : [
                    for policy in config.aws_managed_policies : {
                        id     = format("%s/%s", role, basename(policy))
                        role   = aws_iam_role.role[role].id
                        policy = policy
                    }
                ]
            ]) : data.id => data
        }
    )
}

resource "aws_iam_role" "role" {
  for_each           = local.roles
  name               = each.value.role
  description        = each.value.description
  assume_role_policy = each.value.trust
  tags               = var.tags
}

# This is the custom inline policies that we don't think we will be reusing.
resource "aws_iam_role_policy" "policy_custom" {
  for_each = { for role, config in local.roles: role => config.permissions if config.permissions }
  role     = aws_iam_role.role[each.key].id
  policy   = each.value
  name     = each.key
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each   = local.attach_policies_to_roles
  role       = each.value.role
  policy_arn = each.value.policy
}