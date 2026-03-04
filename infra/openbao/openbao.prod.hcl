ui = false
disable_mlock = false

audit "file" "to-file" {
  options = {
    file_path = "/openbao/audit.log"
    mode      = "0600"
  }
}
