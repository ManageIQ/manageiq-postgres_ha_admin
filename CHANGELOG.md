# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [3.1.2] - 2020-12-21
- Allow for Rails 6.0 [#23](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/23)

## [3.1.1] - 2019-12-12
- Remove the dependency on linux_admin [#19](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/19)

## [3.1.0] - 2019-05-09

### Added
- Add a logical replication config handler [#17](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/17)

## [3.0.1] - 2019-03-19

### Changed
- Remove references to MiqPassword [#15](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/15)

## [3.0.0] - 2018-09-05

### Added
- Allow users of the gem to specify a logger object [#7](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/7)

### Changed
- Make sources of database connection info pluggable [#8](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/8)
- Improve FailoverDatabases/ServerStore class [#9](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/9)
- Make failover monitor generic [#10](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/10)

## [2.0.0] - 2018-08-01

### Added
- Add pg-dsn_parser to the gemspec [#5](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/5)
- Add postgresql addon for travis [#6](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/6)

### Changed
- Make changes for upgrading repmgr to version 4 [#4](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/4)

[Unreleased]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.2...master
[3.1.2]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.1...v3.1.2
[3.1.1]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.0.1...v3.1.0
[3.0.1]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v1.0.0...v2.0.0
