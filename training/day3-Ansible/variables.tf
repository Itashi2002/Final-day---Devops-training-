variable "name" {
  description = "Enter the value to be used for Name attribute & Name tag. E.g. kul-sfl/ram/itashi"
}
variable "password" {
  description = "Enter the password for tomcat GUI user admin"
  sensitive = true
}