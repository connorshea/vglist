target :lib do
  signature "sig"

  check "db"                       # Directory name
  check "lib"                       # Directory name
  check "Gemfile"                   # File name
  check "app/models/**/*.rb"        # Glob
  check "app/controllers/**/*.rb"   # Glob
  check "app/graphql/**/*.rb"       # Glob
  check "app/helpers/**/*.rb"       # Glob
  check "app/policies/**/*.rb"      # Glob
  check "app/services/**/*.rb"      # Glob
  # ignore "lib/templates/*.rb"

  # Standard libraries
  library "pathname", "set"
end

# target :spec do
#   signature "sig", "sig-private"
#
#   check "spec"
#
#   # library "pathname", "set"       # Standard libraries
#   # library "rspec"
# end
