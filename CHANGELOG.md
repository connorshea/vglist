# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## v2019.2.14
### Added
- Add a `Dockerfile` for running the application in production mode. This is a super important step toward actually deploying the thing to production. ([#138])

## v2019.2.13
### Added
- Add Game Engines. ([#135])

## v2019.1.27
### Added
- Improved design and added dropdowns. ([#100])
- Add ActiveStorage, user avatars, and user avatar uploading. ([#104])

### Fixed
- Ensure that users can't have more than one copy of the same release in their library. ([#101])
- Ensure that releases can't have more than one of the same genre. ([#102])

## v2019.1.26
### Added
- Add action for adding a release to your library. ([#93])
- Add action for removing a release from your library. ([#98])
- Add some tests for functionality that was previously untested. ([#99])

## v2019.1.25
### Added
- Add Settings pages and a form for updating your user bio. ([#90])

## v2019.1.24
### Added
- Add create/update/destroy for releases, meaning you can now modify everything about releases from the web interface. ([#82])
- Add simple search for games, platforms, and developers/publishers. Currently only used in the release form. ([#82])
- Add `update_role` method that can be used to promote users to moderator or admin status. Also able to demote. Only admins can do this. ([#85])

## v2019.1.22
### Added
- Upgrade to Webpacker 4. ([#77])
- Add create/update/destroy for platforms. Only moderators and admins can modify platforms. ([#81])

## v2019.1.20
### Added
- Add feature specs. ([#72])

## v2019.1.18
### Added
- Add `vue-select` component. ([#52])
- Add `pg_search` for searching genres in the games form. ([#60])
- Add pundit policies for genres. ([#61])

## v2019.1.14
### Changed
- Move from Bootstrap to Bulma for our CSS framework. ([#48])

## v2019.1.13
### Added
- Add moderators and admins. ([#33])
- Add request specs. ([#47])

## v2019.1.6
### Added
- Add developers and publishers. ([#27])

## v2019.1.4
### Added
- Add Vue.js. ([#26])

### Changed
- Move to Webpack. ([#26])

## v2019.1.2
### Added
- Add genres to games. ([#24])

## v2019.1.1
### Added
- Add shoulda-matchers gem for testing. ([#21])
- Add Pundit gem for authorization. ([#22])

## v2018.12.31
### Changed
- Move to Rspec for testing. ([#19])

## v2018.12.30
### Added
- Add create/update/delete for Games. ([#11])


[#11]: https://github.com/connorshea/ContinueFromCheckpoint/pull/11
[#19]: https://github.com/connorshea/ContinueFromCheckpoint/pull/19
[#21]: https://github.com/connorshea/ContinueFromCheckpoint/pull/21
[#22]: https://github.com/connorshea/ContinueFromCheckpoint/pull/22
[#24]: https://github.com/connorshea/ContinueFromCheckpoint/pull/24
[#26]: https://github.com/connorshea/ContinueFromCheckpoint/pull/26
[#27]: https://github.com/connorshea/ContinueFromCheckpoint/pull/27
[#33]: https://github.com/connorshea/ContinueFromCheckpoint/pull/33
[#47]: https://github.com/connorshea/ContinueFromCheckpoint/pull/47
[#48]: https://github.com/connorshea/ContinueFromCheckpoint/pull/48
[#52]: https://github.com/connorshea/ContinueFromCheckpoint/pull/52
[#60]: https://github.com/connorshea/ContinueFromCheckpoint/pull/60
[#61]: https://github.com/connorshea/ContinueFromCheckpoint/pull/61
[#72]: https://github.com/connorshea/ContinueFromCheckpoint/pull/72
[#77]: https://github.com/connorshea/ContinueFromCheckpoint/pull/77
[#81]: https://github.com/connorshea/ContinueFromCheckpoint/pull/81
[#82]: https://github.com/connorshea/ContinueFromCheckpoint/pull/82
[#85]: https://github.com/connorshea/ContinueFromCheckpoint/pull/85
[#90]: https://github.com/connorshea/ContinueFromCheckpoint/pull/90
[#93]: https://github.com/connorshea/ContinueFromCheckpoint/pull/93
[#98]: https://github.com/connorshea/ContinueFromCheckpoint/pull/98
[#99]: https://github.com/connorshea/ContinueFromCheckpoint/pull/99
[#100]: https://github.com/connorshea/ContinueFromCheckpoint/pull/100
[#101]: https://github.com/connorshea/ContinueFromCheckpoint/pull/101
[#102]: https://github.com/connorshea/ContinueFromCheckpoint/pull/102
[#104]: https://github.com/connorshea/ContinueFromCheckpoint/pull/104
[#135]: https://github.com/connorshea/ContinueFromCheckpoint/pull/135
[#138]: https://github.com/connorshea/ContinueFromCheckpoint/pull/138
