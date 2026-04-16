### cloud vars

variable "service_account_key_file" {
  type        = string
  description = "Path to service account key file"
}

variable "ssh_public_key" {
  type        = string
  description = "Path to public SSH key file"
  default     = "/home/Ollrins/key.pub"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "vm_resources" {
  description = "VM resources"
  type = object({
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    cores  = 2
    memory = 4
    disk   = 20
  }
}

# SSH private key для подключения к ВМ (опционально, если нужно)
variable "ssh_private_key" {
  description = "Path to private SSH key"
  type        = string
  default     = "/home/Ollrins/key"
}