module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled             = var.enabled
  namespace           = var.namespace
  tenant              = var.tenant
  environment         = var.environment
  stage               = var.stage
  name                = var.name
  delimiter           = var.delimiter
  attributes          = var.attributes
  tags                = var.tags
  additional_tag_map  = var.additional_tag_map
  label_order         = var.label_order
  regex_replace_chars = var.regex_replace_chars
  id_length_limit     = var.id_length_limit
  label_key_case      = var.label_key_case
  label_value_case    = var.label_value_case
  descriptor_formats  = var.descriptor_formats

  context = var.context
}

variable "context" {
  type = any
  default = {
    enabled             = true
    namespace           = null
    tenant              = null
    environment         = null
    stage               = null
    name                = null
    delimiter           = null
    attributes          = []
    tags                = {}
    additional_tag_map  = {}
    label_order         = []
    regex_replace_chars = null
    id_length_limit     = null
    label_key_case      = null
    label_value_case    = null
    descriptor_formats  = {}
  }
  description = "Single object for setting entire context at once."
}

variable "enabled" {
  type        = bool
  default     = null
  description = "Set to false to prevent the module from creating any resources."
}

variable "namespace" {
  type        = string
  default     = null
  description = "ID element."
}

variable "tenant" {
  type        = string
  default     = null
  description = "ID element."
}

variable "environment" {
  type        = string
  default     = null
  description = "ID element."
}

variable "stage" {
  type        = string
  default     = null
  description = "ID element."
}

variable "name" {
  type        = string
  default     = null
  description = "ID element."
}

variable "delimiter" {
  type        = string
  default     = null
  description = "Delimiter to be used between ID elements."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "ID element."
}

variable "labels_as_tags" {
  type        = set(string)
  default     = ["default"]
  description = "Set of labels to include as tags."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}

variable "additional_tag_map" {
  type        = map(string)
  default     = {}
  description = "Additional key-value pairs to add to each map in `tags_as_list_of_maps`."
}

variable "label_order" {
  type        = list(string)
  default     = null
  description = "The order in which the labels appear in the ID."
}

variable "regex_replace_chars" {
  type        = string
  default     = null
  description = "Terraform regular expression that if matched, will be replaced with empty string in ID elements."
}

variable "id_length_limit" {
  type        = number
  default     = null
  description = "Limit `id` to this many characters (minimum 6)."
}

variable "label_key_case" {
  type        = string
  default     = null
  description = "Controls the letter case of the `tags` keys for generated tags."
}

variable "label_value_case" {
  type        = string
  default     = null
  description = "Controls the letter case of the `tags` values for generated tags."
}

variable "descriptor_formats" {
  type        = any
  default     = {}
  description = "Describe additional descriptors to be output in the `descriptors` output map."
}
