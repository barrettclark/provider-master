terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}

provider "random" {}

resource "random_shuffle" "names" {
  input = [
    "Barrett Clark",
    "Ishaan Bose",
    "Brandon Croft",
    "Chris Trombley",
    "Luces Huayhuaca",
    "Mark DeCrane",
    "Sebastian Rivera",
    "Ukeme Bassey",
    "Shweta Murali",
    "Garvita Rai",
  ]
}

output "random_names" {
  value = random_shuffle.names.result
}
