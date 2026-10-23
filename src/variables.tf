variable "region" {
  type        = string
  description = "AWS Region"
}

variable "internal" {
  type        = bool
  default     = false
  description = "A boolean flag to determine whether the ALB should be internal"
}

variable "subnet_type" {
  type        = string
  default     = "public"
  description = <<-EOT
    Which subnets of the `vpc` component the ALB is placed in: `public` or `private`.
    Use `private` together with `internal = true` for an ALB that is reached only from inside the VPC
    (for example behind a Network Load Balancer). Changing this replaces the ALB.
    EOT

  validation {
    condition     = contains(["public", "private"], var.subnet_type)
    error_message = "subnet_type must be either \"public\" or \"private\"."
  }
}

variable "http_port" {
  type        = number
  default     = 80
  description = "The port for the HTTP listener"
}

variable "http_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP listener"
}

variable "http_redirect" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP redirect to HTTPS"
}

variable "http_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow in HTTP security group"
}

variable "http_ingress_prefix_list_ids" {
  type        = list(string)
  default     = []
  description = "List of prefix list IDs for allowing access to HTTP ingress security group"
}

variable "https_port" {
  type        = number
  default     = 443
  description = "The port for the HTTPS listener"
}

variable "https_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTPS listener"
}

variable "https_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow in HTTPS security group"
}

variable "https_ingress_prefix_list_ids" {
  type        = list(string)
  default     = []
  description = "List of prefix list IDs for allowing access to HTTPS ingress security group"
}

variable "https_ssl_policy" {
  type        = string
  description = "The name of the SSL Policy for the listener"
  default     = "ELBSecurityPolicy-TLS13-1-3-2021-06"
}

variable "access_logs_prefix" {
  type        = string
  default     = ""
  description = "The S3 log bucket prefix"
}

variable "access_logs_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable access_logs"
}

variable "access_logs_s3_bucket_id" {
  type        = string
  default     = null
  description = "An external S3 Bucket name to store access logs in. If specified, no logging bucket will be created."
}

variable "cross_zone_load_balancing_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable cross zone load balancing"
}

variable "http2_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP/2"
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle"
}

variable "ip_address_type" {
  type        = string
  default     = "ipv4"
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are `ipv4` and `dualstack`."
}

variable "deletion_protection_enabled" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable deletion protection for ALB"
}

variable "deregistration_delay" {
  type        = number
  default     = 15
  description = "The amount of time to wait in seconds before changing the state of a deregistering target to unused"
}

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "The destination for the health check request"
}

variable "health_check_port" {
  type        = string
  default     = "traffic-port"
  description = "The port to use for the healthcheck"
}

variable "health_check_timeout" {
  type        = number
  default     = 10
  description = "The amount of time to wait in seconds before failing a health check request"
}

variable "health_check_healthy_threshold" {
  type        = number
  default     = 2
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  default     = 2
  description = "The number of consecutive health check failures required before considering the target unhealthy"
}

variable "health_check_interval" {
  type        = number
  default     = 15
  description = "The duration in seconds in between health checks"
}

variable "health_check_matcher" {
  type        = string
  default     = "200-399"
  description = "The HTTP response codes to indicate a healthy check"
}

variable "alb_access_logs_s3_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "A boolean that indicates all objects should be deleted from the ALB access logs S3 bucket so that the bucket can be destroyed without error"
}

variable "target_group_port" {
  type        = number
  default     = 80
  description = "The port for the default target group"
}

variable "target_group_protocol" {
  type        = string
  default     = "HTTP"
  description = "The protocol for the default target group HTTP or HTTPS"
}

variable "target_group_name" {
  type        = string
  default     = ""
  description = "The name for the default target group, uses a module label name if left empty"
}

variable "target_group_target_type" {
  type        = string
  default     = "ip"
  description = "The type (`instance`, `ip` or `lambda`) of targets that can be registered with the target group"
}

variable "lifecycle_rule_enabled" {
  type        = bool
  description = "A boolean that indicates whether the s3 log bucket lifecycle rule should be enabled."
  default     = true
}

variable "stickiness" {
  type = object({
    cookie_duration = number
    enabled         = bool
  })
  description = "Target group sticky configuration"
  default     = null
}

variable "vpc_component_name" {
  type        = string
  default     = "vpc"
  description = "Atmos `vpc` component name"
}

variable "dns_delegated_component_name" {
  type        = string
  default     = "dns-delegated"
  description = "Atmos `dns-delegated` component name"
}

variable "dns_delegated_environment_name" {
  type        = string
  default     = null
  description = "`dns-delegated` component environment name"
}

variable "acm_component_name" {
  type        = string
  default     = "acm"
  description = "Atmos `acm` component name"
}

variable "dns_acm_enabled" {
  type        = bool
  default     = false
  description = "If `true`, use the ACM ARN created by the given `dns-delegated` component. Otherwise, use the ACM ARN created by the given `acm` component."
}

variable "drop_invalid_header_fields" {
  type        = bool
  default     = false
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false)."
}

variable "route53_record_names" {
  type        = list(string)
  default     = []
  description = "List of Route53 A ALIAS record names to create pointing to the ALB. When non-empty, `route53_zone_name` is required."
}

variable "route53_zone_name" {
  type        = string
  default     = null
  description = "The name of the Route53 hosted zone in which to create alias records. Required when `route53_record_names` is non-empty."
}

variable "desync_mitigation_mode" {
  type        = string
  default     = "defensive"
  description = "How the load balancer handles requests that might pose a security risk to an application due to HTTP desync. Valid values are `monitor`, `defensive` (default), `strictest`."

  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "Allowed values: `monitor`, `defensive`, or `strictest`."
  }
}

variable "health_check_protocol" {
  type        = string
  default     = null
  description = "The protocol to use for the healthcheck. If not specified, same as the traffic protocol"
}

variable "load_balancing_algorithm_type" {
  type        = string
  default     = "round_robin"
  description = "Determines how the load balancer selects targets when routing requests. Only applicable for Application Load Balancer Target Groups"
}

variable "default_target_group_enabled" {
  type        = bool
  default     = true
  description = "Whether the default target group should be created or not."
}

variable "target_group_protocol_version" {
  type        = string
  default     = "HTTP1"
  description = "The protocol version for the default target group. One of `HTTP1`, `HTTP2`, `GRPC`."

  validation {
    condition     = contains(["HTTP1", "HTTP2", "GRPC"], var.target_group_protocol_version)
    error_message = "Allowed values: `HTTP1`, `HTTP2`, or `GRPC`."
  }
}

variable "listeners" {
  type = map(object({
    port                    = number
    protocol                = optional(string, "HTTPS")
    certificate_arn         = optional(string)
    ssl_policy              = optional(string)
    target_port             = optional(number)
    target_protocol         = optional(string)
    target_protocol_version = optional(string, "HTTP1")
    target_type             = optional(string)
    deregistration_delay    = optional(number)
    ingress_cidr_blocks     = optional(list(string), [])
    health_check = optional(object({
      enabled             = optional(bool, true)
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string)
      matcher             = optional(string, "200-399")
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 2)
      interval            = optional(number, 15)
      timeout             = optional(number, 10)
    }), {})
    targets = optional(list(object({
      id   = string
      port = optional(number)
    })), [])
  }))
  default     = {}
  description = <<-EOT
    Additional listeners, keyed by name. Each key creates its own target group, listener and (when
    `ingress_cidr_blocks` is set) security group ingress rule on the ALB, so one ALB can serve any number of ports.
    - `port`, `protocol`: listener port and protocol (`HTTPS` or `HTTP`, default `HTTPS`).
    - `certificate_arn`, `ssl_policy`: for `HTTPS` listeners; default to the component's certificate and `https_ssl_policy`.
    - `target_port`, `target_protocol`, `target_protocol_version`: target group settings; port and protocol default to the listener's.
    - `target_type`, `deregistration_delay`: default to `target_group_target_type` and `deregistration_delay`.
    - `ingress_cidr_blocks`: CIDRs allowed to reach this listener on the ALB security group.
    - `health_check`: target group health check; `protocol` defaults to the target protocol.
    - `targets`: targets to register (`id` is an instance ID, IP address or Lambda ARN depending on `target_type`; `port` defaults to the target port).
    EOT

  validation {
    condition     = alltrue([for l in values(var.listeners) : contains(["HTTP", "HTTPS"], l.protocol)])
    error_message = "listeners[*].protocol must be HTTP or HTTPS."
  }

  validation {
    condition     = alltrue([for l in values(var.listeners) : l.target_protocol == null || contains(["HTTP", "HTTPS"], l.target_protocol)])
    error_message = "listeners[*].target_protocol must be HTTP or HTTPS."
  }

  validation {
    condition     = length(distinct([for l in values(var.listeners) : l.port])) == length(var.listeners)
    error_message = "listeners[*].port must be unique."
  }
}
