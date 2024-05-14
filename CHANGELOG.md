# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [3.3.0] - 2024-05-14
### Added
- Rails 7 support [#43](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/43)

## [3.2.1] - 2023-03-22
### Changed
- Improve failover logging [#39](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/39)

## [3.2.0] - 2022-09-26
### Added
- Add simple prefix to all log lines [#38](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/38)

### Changed
- 5 minute db checks is too long, use 2 minutes [#37](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/37)

### Removed
- Remove unused pglogical_config_handler [#35](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/35)

### Fixed
- Don't attempt a database failover without a known standby [#36](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/36)

## [3.1.4] - 2022-04-30
### Changed
- Loosen rails dependency to include rails 6.1 [#28](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/28)

## [3.1.3] - 2021-09-27
### Changed
- Loosen manageiq-password dependency to < 2 [#26](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/26)
- Update ruby versions to 2.5.8 minimum and support Ruby 3.0 [#25](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/25)
- Switch to manageiq-style [#24](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/24)

## [3.1.2] - 2020-12-21
### Changed
- Allow for Rails 6.0 [#23](https://github.com/ManageIQ/manageiq-postgres_ha_admin/pull/23)

## [3.1.1] - 2019-12-12
### Changed
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

[Unreleased]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.3.0...master
[3.3.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.2.1...v3.3.0
[3.2.1]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.4...v3.2.0
[3.1.4]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.3...v3.1.4
[3.1.3]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.2...v3.1.3
[3.1.2]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.1...v3.1.2
[3.1.1]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.0.1...v3.1.0
[3.0.1]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/ManageIQ/manageiq-postgres_ha_admin/compare/v1.0.0...v2.0.0
