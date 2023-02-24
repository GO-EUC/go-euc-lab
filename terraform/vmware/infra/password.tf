resource "random_password" "password" {
    length           = 10
    min_lower        = 1
    min_upper        = 1
    min_special      = 1
    min_numeric      = 1
    special          = true
    override_special = "!#$%&"
}
