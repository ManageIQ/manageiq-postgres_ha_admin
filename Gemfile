source 'https://rubygems.org'

# Specify your gem's dependencies in manageiq-postgres_ha_admin.gemspec
gemspec

minimum_version =
  case ENV['TEST_RAILS_VERSION']
  when "8.0"
    "~>8.0.4"
  else
    "~>7.2.3"
  end

gem "activesupport", minimum_version
