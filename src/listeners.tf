locals {
  listeners = module.this.enabled ? var.listeners : {}

  listener_ingress_rules = {
    for key, listener in local.listeners : key => {
      port        = listener.port
      cidr_blocks = listener.ingress_cidr_blocks
      description = "${key} listener (${listener.protocol} ${listener.port})"
    } if length(listener.ingress_cidr_blocks) > 0
  }

  listener_target_attachments = {
    for attachment in flatten([
      for key, listener in local.listeners : [
        for target in listener.targets : {
          key       = "${key}/${target.id}/${coalesce(target.port, listener.target_port, listener.port)}"
          listener  = key
          target_id = target.id
          port      = coalesce(target.port, listener.target_port, listener.port)
        }
      ]
    ]) : attachment.key => attachment
  }
}

module "listener_target_group_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  for_each = local.listeners

  attributes      = [each.key]
  id_length_limit = 32

  context = module.this.context
}

resource "aws_lb_target_group" "listener" {
  for_each = local.listeners

  name                 = module.listener_target_group_label[each.key].id
  port                 = coalesce(each.value.target_port, each.value.port)
  protocol             = coalesce(each.value.target_protocol, each.value.protocol)
  protocol_version     = each.value.target_protocol_version
  target_type          = coalesce(each.value.target_type, var.target_group_target_type)
  vpc_id               = module.vpc.outputs.vpc_id
  deregistration_delay = coalesce(each.value.deregistration_delay, var.deregistration_delay)

  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = coalesce(each.value.health_check.protocol, each.value.target_protocol, each.value.protocol)
    matcher             = each.value.health_check.matcher
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = module.listener_target_group_label[each.key].tags
}

resource "aws_lb_listener" "listener" {
  for_each = local.listeners

  load_balancer_arn = module.alb.alb_arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.protocol == "HTTPS" ? coalesce(each.value.certificate_arn, local.certificate_arn) : null
  ssl_policy        = each.value.protocol == "HTTPS" ? coalesce(each.value.ssl_policy, var.https_ssl_policy) : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.listener[each.key].arn
  }

  tags = module.listener_target_group_label[each.key].tags
}

resource "aws_lb_target_group_attachment" "listener" {
  for_each = local.listener_target_attachments

  target_group_arn = aws_lb_target_group.listener[each.value.listener].arn
  target_id        = each.value.target_id
  port             = each.value.port
}

resource "aws_security_group_rule" "listener_ingress" {
  for_each = local.listener_ingress_rules

  type              = "ingress"
  security_group_id = module.alb.security_group_id
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}
