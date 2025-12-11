# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/postgres_ha_admin/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-postgres_ha_admin"
  spec.version       = ManageIQ::PostgresHaAdmin::VERSION
  spec.authors       = ["ManageIQ Developers"]

  spec.summary       = "ManageIQ Postgres H.A. Admin"
  spec.description   = "ManageIQ Postgres H.A. Admin"
  spec.homepage      = "https://github.com/ManageIQ/manageiq-postgres_ha_admin"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.metadata    = {
    "changelog_uri" => "https://github.com/ManageIQ/manageiq-postgres_ha_admin/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/ManageIQ/manageiq-postgres_ha_admin/",
    "bug_tracker_uri" => "https://github.com/ManageIQ/manageiq-postgres_ha_admin/issues"
  }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2"

  spec.add_runtime_dependency "activesupport",     ">=7.2.3", "<8.1"
  spec.add_runtime_dependency "awesome_spawn",     "~> 1.4"
  spec.add_runtime_dependency "manageiq-password", "< 2"
  spec.add_runtime_dependency "pg"
  spec.add_runtime_dependency "pg-dsn_parser",     "~> 0.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",     "~> 3.0"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
