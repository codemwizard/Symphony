ui = true
disable_mlock = true

# Declarative audit device (OpenBao requires config-based audit management)
audit "file" "to-file" {
  options = {
    file_path = "/openbao/audit.log"
    mode      = "0600"
  }
}
