target :lib do
  signature "sig"

  check "db"
  check "lib"
  check "app/models"
  check "app/controllers"
  check "app/graphql"
  check "app/helpers"
  check "app/policies"
  check "app/services"

  # Standard libraries
  library "pathname", "set"

  repo_path "vendor/rbs/gem_rbs/gems"
  library 'actionpack', 'actionview', 'activejob', 'activemodel', 'activerecord', 'activesupport', 'listen', 'railties'
end

# target :spec do
#   signature "sig", "sig-private"
#
#   check "spec"
#
#   # library "pathname", "set"       # Standard libraries
#   # library "rspec"
# end
