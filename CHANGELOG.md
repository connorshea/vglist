# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## v2021.2.28
### Added
- Add filters and sorting to games queries in GraphQL API. ([#1906], [#1907])

## v2021.2.27
### Added
- Add `deleteEvent` mutation to GraphQL API. ([#1895])

## v2021.1.24
### Added
- Add Internet Game Database IDs. ([#1817])

## v2021.1.21
### Added
- Add audit logs via the paper_trail gem for tracking changes to companies, games, genres, engines, platforms, and series records. Now every change to a record is tracked including the contents of the change and the user that changed it. ([#1806])

## v2021.1.9
### Changed
- Change the user lists on game pages to a grid of avatar images. ([#1771])

## v2021.1.2
### Changed
- Update the copyright year, Happy New Year! :)
- Limit the sizes of the cover and avatar images in the GraphQL API, and use the fully-qualified URL rather than just the path. This is a breaking change for API users. ([#1747])

### Fixed
- Prevent ActiveStorage from attempting to create different sizes of WebP images, since ImageMagick can't handle those right now. ([#1746])

## v2020.12.21
### Changed
- Update Ruby version for vglist from 2.6.6 to 2.7.2. ([#1712])

## v2020.12.19
### Added
- Add [Cloudflare Web Analytics](https://www.cloudflare.com/web-analytics/) so we can track some basic analytics data. ([#1696])

## v2020.12.13
### Fixed
- Fix a bug causing library table dropdowns to not work. ([#1684])

## v2020.12.9
### Changed
- Upgrade Ruby on Rails to Rails 6.1. ([#1678])

## v2020.12.2
### Added
- Add `currentUser` query for GraphQL API. ([#1668])

### Fixed
- Fix issue with CORS that was preventing the OAuth authentication flow from working via a webpage. ([#1667])

## v2020.11.28
### Added
- Add the ability to update 'Hours Played' for existing games in your library via the Steam importer. ([#1649])

## v2020.10.17
### Changed
- Update Sentry configuration to use Releases and to split the frontend and backend error tracking projects, so errors are easier to discover and fix. ([#1568])

## v2020.9.12
### Added
- Add a dark mode. This is controlled by the `prefers-color-scheme` media query, which means it's determined by browsers. Some browsers let you specify whether you want a dark or light mode for websites, and some just use the theme value from the operating system. ([#1501])

## v2020.9.7
### Fixed
- Fix the "Sign out" button which broke after a refactor a few weeks ago. ([#1488])

## v2020.7.16
### Added
- Add the ability for admins to merge game entries together. This can be used to fix duplicate games and will update related game purchases and favorites so the data isn't lost. If a user has added both the original and duplicate games to their library, one of the entries will be deleted. ([#1403])

## v2020.7.8
### Added
- Add Steam Blocklist, for preventing the creation of games for specific Steam IDs. This is mostly useful for soundtracks, test servers, software, and other non-game stuff on Steam. ([#1394])

### Changed
- Change the user statistics calculations to ignore N/A games and count 'Dropped' as completed. ([#1392])

## v2020.7.3
### Added
- Add a "More..." button to game results in the search bar, it can be used to show more games if your search doesn't return the game you're looking for on the first page. ([#1378])

## v2020.6.14
### Fixed
- Fix the GraphiQL Docs Explorer sidebar by providing a static schema file. ([#1331])

## v2020.6.13
### Changed
- Replace existing API token authentication system with an encrypted API token field. ([#1329])
  - NOTE: This will require recreating your API tokens if you were using the API before this change.

## v2020.5.24
### Added
- Upgrade GraphiQL and enable it in production. It's available at `/graphiql`. ([#1262])

## v2020.5.17
### Added
- Add User search. ([#1249])

## v2020.5.4
### Added
- Add sorting by most followers and most games to the users page. ([#1218])

## v2020.5.3
### Added
- Add a user count to the "Followers" and "Following" tabs on the User Profile. ([#1202])

### Changed
- Change the 'highest average rating' filter in the games list to only include games with at least 5 owners. ([#1212], [#1213])

## v2020.5.2
### Added
- Add replay counts for games in user libraries, for tracking the number of times a user has replayed a given game (Thanks @AnthonySuper!). ([#1185], [#1198])

### Fixed
- Fix game covers extending outside of their intended boundary and covering other elements. ([#1197])

## v2020.4.29
### Added
- Add a game count to user cards. ([#1182])

### Changed
- Rebuilt the Steam importer as a service to move code out of the controller and to make it run faster (Thanks @AnthonySuper!). ([#1174])
- Made it so only moderators and admins can remove game covers. ([#1181])

## v2020.4.28
### Added
- Add database indices to enforce uniqueness.

### Changed
- Made it so only moderators and admins can delete games.

## v2020.3.25
### Added
- Include the game cover and other metadata in game search results. ([#1123])

## v2020.2.16
### Added
- Add a dropdown to game cards, currently just used for favoriting games. ([#1044])

## v2020.2.8
### Added
- Add sorting by average rating to Games. ([#1021])

## v2020.2.2
### Added
- Add GOG.com IDs to Games. ([#1014])

## v2020.1.27
### Added
- Add Epic Games Store IDs to Games. ([#996])

## v2020.1.25
### Added
- Add icons to the search bar, various buttons, dropdowns, etc. ([#987], [#989], [#990])

## v2020.1.15
### Added
- Add the ability for moderators and admins to ban and unban users. ([#971])

## v2020.1.11
### Fixed
- Fix a CORS issue that prevented sending API requests from other websites. ([#960])

## v2019.12.22
### Added
- Add Stores to the Library Edit Bar. ([#917])

### Changed
- Improve the design of the user registration and login pages. ([#918])

## v2019.12.15
### Changed
- Improve Rake tasks for importing data from Wikidata, can now update existing games with new information more easily. ([#897])

## v2019.12.13
### Added
- Add support for long-lasting API tokens. ([#884])

## v2019.11.29
### Added
- Add `updateGameInLibrary` mutation to API. ([#859])
- Add Schema Linter for GraphQL API. ([#860])

### Fixed
- Update graphql-ruby to fix pagination in the API. ([#861])

## v2019.11.27
### Added
- Add Export Library page in Settings. This allows users to export their entire vglist game library as a JSON file. ([#852])

## v2019.11.23
### Added
- Add Stores for keeping track of the places where you own games. ([#842])

## v2019.11.4
### Added
- Add Giant Bomb IDs along with an importer for them from Wikidata. ([#811])

## v2019.11.1
### Changed
- Remove descriptions from games, genres, platforms, and companies. They were essentially unused and just invited spam/trolling. ([#803])

## v2019.10.19
### Changed
- Allow more than one Steam App ID for a given game, and add Steam App IDs to the GraphQL API. This should improve the accuracy of the Steam library importer. ([#778])

## v2019.10.13
### Added
- Add 'list' queries to the GraphQL API, for example listing all existing genres on the site. ([#761])

## v2019.10.12
### Added
- Add pagination to the GraphQL API. ([#760])

## v2019.10.11
### Added
- Add GraphQL mutations for follow/unfollowUser, add/removeGameFromLibrary, and favorite/unfavoriteGame. ([#757], [#758], [#759])

## v2019.10.7
### Changed
- Various improvements to the GraphQL API. ([#738], [#747], [#755], [#756])

## v2019.10.5
### Added
- Add OAuth for API authentication. ([#711])

## v2019.9.29
### Added
- Add a favicon and logo! ([#712])

## v2019.9.27
### Added
- Add support for the `/.well-known/change-password` route.

## v2019.9.23
### Added
- Add a GraphQL API (currently disabled until the OAuth system is finished and the API is documented). ([#697])

## v2019.9.15
### Added
- Add filtering by release year to games. ([#681])

## v2019.9.14
### Added
- Add some functionality to block Wikidata IDs from being added to the database. The purpose of this functionality is to prevent bad data (e.g. Wikidata has entries for sets of Pokemon games as one entry, like 'Pokemon Sun & Moon') from being introduced into the site. ([#678])

## v2019.9.8
### Added
- Add an event for when one user follows another. ([#670])

### Changed
- Have every user follow User with ID 1 by default. ([#667])

## v2019.9.7
### Added
- Add a 'Following' Activity view for viewing only activity from users you follow. ([#665])

## v2019.9.2
### Added
- Add a basic system for following users. ([#656])

### Changed
- Improve error handling when adding games to your library. ([#652])

### Fixed
- Fix multiselect dropdowns not working. ([#654])

## v2019.8.31
### Added
- Add Average Rating to game pages. ([#638])
- Add Release Dates for Games. ([#639], [#640], [#641])

## v2019.8.29
### Added
- Add User Activity Feeds. ([#632])

## v2019.8.26
### Added
- Add events for favoriting games and users creating their accounts. ([#630])

## v2019.8.25
### Added
- Add Private Accounts. ([#628])

## v2019.8.23
### Changed
- Increase character limit to 2000 for comments on games in the game library.

## v2019.8.20
### Added
- Add a global Activity Feed where events like games being added to a user's library or a user completing a game are logged. ([#617])

## v2019.8.16
### Changed
- Upgrade Rails to Rails 6.0.0. ([#180], [#615], [#616])

### Fixed
- Fix some bugs with vue-good-table, CSP, and dropdowns. ([#614])

## v2019.8.8
### Changed
- Update Sorbet and add some Sorbet signatures. ([#598])

## v2019.8.3
### Added
- Add mass editing for game libraries. ([#584])

### Fixed
- Fix dropdowns not closing properly.

## v2019.7.31
### Added
- Add Sorbet typechecking to CI. ([#577])

### Changed
- Update Faker to 2.0.0. ([#575])

### Fixed
- Fix Wikidata import task by adding a user agent to every request. ([#572])

## v2019.7.28
### Added
- Add Sorbet typechecking! ([#561])

### Fixed
- Fix deploy task failing to `bundle install` sometimes.

## v2019.6.19
### Changed
- Convert all JavaScript in the project to TypeScript. ([#506])

## v2019.6.11
### Changed
- Improve design of library comparison page. ([#495])

## v2019.6.3
### Added
- Add a page for comparing libraries between users. ([#474])

## v2019.6.1
### Changed
- Improve the design of the avatar uploader. ([#473])

## v2019.5.18
### Added
- Add a cover importer for importing covers from MobyGames. Added around 7000 new covers with this. ([#438])

### Fixed
- Fix an issue with user statistics for users that have capital letters in their usernames.

## v2019.5.16
### Added
- Add MobyGames IDs to games. ([#436])
- Add importer for MobyGames IDs from Wikidata. ([#436])

## v2019.5.9
### Added
- Add library statistics to the user page. ([#411])

### Changed
- Limit deletion of series' and engines.

## v2019.5.5
### Added
- The 'Add to library' button on game pages now uses a modal dialog so game details can be filled in from that page. It also allows editing when a game is already in your library. ([#401])

## v2019.5.4
### Added
- Add a 'Paused' status to the Completion Statuses. This is for when you've stopped playing a game, but intend to pick it up again in the future. ([#397])

### Fixed
- Fix the game form so the series value can actually be removed. ([#398])
- Fix Account Settings redirecting to an unstyled page when the form submit failed. ([#399])
- Fix Vue components 'blinking' and reverting to their initial state when changing pages. ([#400])

## v2019.4.27
### Added
- Add platform filter on games index. ([#391])

## v2019.4.23
### Added
- Add Sentry for JavaScript error reporting. ([#386])
- Add dropdown to toggle column visibility in game library table. ([#387])

## v2019.4.21
### Added
- Add sorting option for games with the most owners. ([#373])

### Changed
- Most buttons are now full-width on mobile, so they're easier to press and don't go off the screen. ([#374])

## v2019.4.20
### Fixed
- Fix a variety of issues related to improper handling of record deletion. ([#370])

## v2019.4.18
### Added
- Add sorting options to the games index. ([#362])

## v2019.4.16
### Added
- Let moderators and admins remove other users' avatars. ([#355])

## v2019.4.13
### Added
- Add OpenGraph meta tags so game covers, user avatars, the site name, etc. show up in embeds (e.g. on Discord or Facebook). ([#342])
- Add a link to this Changelog in the header dropdown. ([#343])

### Fixed
- Fix user avatar aspect ratios, now they're always squares no matter what's uploaded. ([#338])
- Replace chromedriver-helper with webdrivers gem. ([#340])

## v2019.4.8
### Changed
- Add Sentry for error tracking. ([#333])

## v2019.4.7
### Changed
- Update Steam importer. Now just takes the user's Steam username, no login. Also displays the games that weren't imported because they couldn't be matched to a game in the site database. ([#318])
- Clean up the `README.md` instructions and the development database config (thanks @PanisSupraOmnia!). ([#304])

## v2019.4.6
### Added
- Upgrade the game library to use vue-good-table, which provides a better design as well as sorting and other features. ([#315])

### Changed
- Render users as cards on the users index. ([#317])

## v2019.4.4
### Added
- Add Prettier for JavaScript, SCSS, and Vue file formatting. ([#312])

## v2019.4.3
### Added
- Add a button to the settings that allows a user to reset their game library. ([#309])

## v2019.3.31
### Added
- Add Steam account login and the ability to import games from a user's Steam library. ([#297])

## v2019.3.30
### Changed
- Debounce search results so there are fewer requests sent to the backend. ([#295])

### Fixed
- Fix adding a game to your own library and add a feature test to make sure it can't break again. ([#291], [#292])

## v2019.3.29
### Added
- Add a Rake task for deploying the site in production.
- Add a proper description of the site to the About page.

## v2019.3.28
### Added
- First proper deployment to [the live website!](https://vglist.co) Involved setting up a server on DigitalOcean, a database, configuring SSL certs, setting up email, and getting the Rails app to behave properly in production.

### Changed
- Allow the games import script to import games incrementally. ([#285])

## v2019.3.24
### Added
- Add platforms to game purchases. ([#271])

### Fixed
- Fix a bug that prevented more than one person from favoriting the same game. ([#272])

## v2019.3.23
### Changed
- Improve test coverage for cases where the tests didn't check for associations (e.g. a game with a platform). ([#268])
- Rename the project to VideoGameList aka VGList. ([#269])

## v2019.3.22
### Changed
- Improve the design of the settings page. ([#258])
- Enable trigram search to make the search more flexible. ([#265])
- Split `seeds.rb` into multiple files and Rake tasks. ([#267])

## v2019.3.17
### Added
- Add Steam Application IDs to games. ([#239])
- Add a `rake import:full` task for running all the import tasks sequentially. ([#239])
- Add Wikidata IDs to various forms. ([#241])

### Changed
- Allow the search bar to use the arrow keys for navigating between results. ([#238])

## v2019.3.16
### Added
- Add hours played to game purchases. ([#227])

## v2019.3.13
### Added
- Add favoriting games. ([#226])

## v2019.3.11
### Added
- Add start and completion dates to game purchases. ([#223])

## v2019.3.10
### Added
- Add global search to the navbar. Can be used to search for games, companies, genres, engines, series', and platforms. ([#210])
- Add proper game library management to the user page, including adding, editing, and removing games. ([#213])
- Add completion statuses to game purchases. Statuses include Unplayed, In Progress, Dropped, Completed, 100% Completed, and N/A. ([#219])

## v2019.3.9
### Added
- Add request and policy tests for game purchases. ([#207])

## v2019.3.7
### Added
- Add a Rake task to import game covers from PCGamingWiki. ([#206])

## v2019.3.5
### Added
- Add a Rake task to import games from Wikidata. ([#200])
- Add PCGamingWiki IDs to games and import them with the Wikidata Importer. ([#202])

## v2019.3.4
### Added
- Add Rake tasks to import companies, engines, genres, platforms, and series' from Wikidata. ([#198])
- Add Wikidata IDs for companies, engines, games, genres, platforms, and series. ([#199])

## v2019.2.28
### Added
- Add scores to game purchases. ([#186])

## v2019.2.27
### Added
- Add Game Series. ([#182])

## v2019.2.24
### Added
- Add proper error handling to the game form. ([#172])
- Add cancel buttons to forms. ([#173])

## v2019.2.23
### Added
- Add the ability to remove covers from games. ([#168])
- Add the ability to remove avatars from users. ([#169])

## v2019.2.22
### Changed
- Switch CI from Travis to GitLab CI. ([#163])

## v2019.2.18
### Added
- Create a generic multi-select Vue component and replace the existing selector components with it. ([#157])
- Add the `friendly_id` gem and have user URLs use the actual username (e.g. a user named 'spiderman' will have the URL `/users/spiderman`). ([#158])

## v2019.2.17
### Changed
- Remove releases and simplify the site so Games are used for everything. ([#153])

## v2019.2.16
### Added
- Add game cards with a much better design for the `games#index`. ([#148])
- Display developers and publishers from releases on game pages. ([#148])
- Add avatars and covers to `seeds.rb`. ([#150])

## v2019.2.15
### Added
- Add Covers for Games. ([#145])

### Changed
- Change the `Dockerfile` base image Debian to Alpine Linux. ([#144])

## v2019.2.14
### Added
- Add a `Dockerfile` for running the application in production mode. This is a super important step toward actually deploying the thing to production. ([#138])

## v2019.2.13
### Added
- Add Game Engines. ([#135])

## v2019.1.27
### Added
- Improve design and add dropdowns. ([#100])
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

[#11]: https://github.com/connorshea/vglist/pull/11
[#19]: https://github.com/connorshea/vglist/pull/19
[#21]: https://github.com/connorshea/vglist/pull/21
[#22]: https://github.com/connorshea/vglist/pull/22
[#24]: https://github.com/connorshea/vglist/pull/24
[#26]: https://github.com/connorshea/vglist/pull/26
[#27]: https://github.com/connorshea/vglist/pull/27
[#33]: https://github.com/connorshea/vglist/pull/33
[#47]: https://github.com/connorshea/vglist/pull/47
[#48]: https://github.com/connorshea/vglist/pull/48
[#52]: https://github.com/connorshea/vglist/pull/52
[#60]: https://github.com/connorshea/vglist/pull/60
[#61]: https://github.com/connorshea/vglist/pull/61
[#72]: https://github.com/connorshea/vglist/pull/72
[#77]: https://github.com/connorshea/vglist/pull/77
[#81]: https://github.com/connorshea/vglist/pull/81
[#82]: https://github.com/connorshea/vglist/pull/82
[#85]: https://github.com/connorshea/vglist/pull/85
[#90]: https://github.com/connorshea/vglist/pull/90
[#93]: https://github.com/connorshea/vglist/pull/93
[#98]: https://github.com/connorshea/vglist/pull/98
[#99]: https://github.com/connorshea/vglist/pull/99
[#100]: https://github.com/connorshea/vglist/pull/100
[#101]: https://github.com/connorshea/vglist/pull/101
[#102]: https://github.com/connorshea/vglist/pull/102
[#104]: https://github.com/connorshea/vglist/pull/104
[#135]: https://github.com/connorshea/vglist/pull/135
[#138]: https://github.com/connorshea/vglist/pull/138
[#144]: https://github.com/connorshea/vglist/pull/144
[#145]: https://github.com/connorshea/vglist/pull/145
[#148]: https://github.com/connorshea/vglist/pull/148
[#150]: https://github.com/connorshea/vglist/pull/150
[#153]: https://github.com/connorshea/vglist/pull/153
[#157]: https://github.com/connorshea/vglist/pull/157
[#158]: https://github.com/connorshea/vglist/pull/158
[#163]: https://github.com/connorshea/vglist/pull/163
[#168]: https://github.com/connorshea/vglist/pull/168
[#169]: https://github.com/connorshea/vglist/pull/169
[#172]: https://github.com/connorshea/vglist/pull/172
[#173]: https://github.com/connorshea/vglist/pull/173
[#180]: https://github.com/connorshea/vglist/pull/180
[#182]: https://github.com/connorshea/vglist/pull/182
[#186]: https://github.com/connorshea/vglist/pull/186
[#198]: https://github.com/connorshea/vglist/pull/198
[#199]: https://github.com/connorshea/vglist/pull/199
[#200]: https://github.com/connorshea/vglist/pull/200
[#202]: https://github.com/connorshea/vglist/pull/202
[#206]: https://github.com/connorshea/vglist/pull/206
[#207]: https://github.com/connorshea/vglist/pull/207
[#210]: https://github.com/connorshea/vglist/pull/210
[#213]: https://github.com/connorshea/vglist/pull/213
[#219]: https://github.com/connorshea/vglist/pull/219
[#223]: https://github.com/connorshea/vglist/pull/223
[#226]: https://github.com/connorshea/vglist/pull/226
[#227]: https://github.com/connorshea/vglist/pull/227
[#238]: https://github.com/connorshea/vglist/pull/238
[#239]: https://github.com/connorshea/vglist/pull/239
[#241]: https://github.com/connorshea/vglist/pull/241
[#258]: https://github.com/connorshea/vglist/pull/258
[#265]: https://github.com/connorshea/vglist/pull/265
[#267]: https://github.com/connorshea/vglist/pull/267
[#268]: https://github.com/connorshea/vglist/pull/268
[#269]: https://github.com/connorshea/vglist/pull/269
[#271]: https://github.com/connorshea/vglist/pull/271
[#272]: https://github.com/connorshea/vglist/pull/272
[#285]: https://github.com/connorshea/vglist/pull/285
[#291]: https://github.com/connorshea/vglist/pull/291
[#292]: https://github.com/connorshea/vglist/pull/292
[#295]: https://github.com/connorshea/vglist/pull/295
[#297]: https://github.com/connorshea/vglist/pull/297
[#304]: https://github.com/connorshea/vglist/pull/304
[#309]: https://github.com/connorshea/vglist/pull/309
[#312]: https://github.com/connorshea/vglist/pull/312
[#315]: https://github.com/connorshea/vglist/pull/315
[#317]: https://github.com/connorshea/vglist/pull/317
[#318]: https://github.com/connorshea/vglist/pull/318
[#333]: https://github.com/connorshea/vglist/pull/333
[#338]: https://github.com/connorshea/vglist/pull/338
[#340]: https://github.com/connorshea/vglist/pull/340
[#342]: https://github.com/connorshea/vglist/pull/342
[#343]: https://github.com/connorshea/vglist/pull/343
[#355]: https://github.com/connorshea/vglist/pull/355
[#362]: https://github.com/connorshea/vglist/pull/362
[#370]: https://github.com/connorshea/vglist/pull/370
[#373]: https://github.com/connorshea/vglist/pull/373
[#374]: https://github.com/connorshea/vglist/pull/374
[#386]: https://github.com/connorshea/vglist/pull/386
[#387]: https://github.com/connorshea/vglist/pull/387
[#391]: https://github.com/connorshea/vglist/pull/391
[#397]: https://github.com/connorshea/vglist/pull/397
[#398]: https://github.com/connorshea/vglist/pull/398
[#399]: https://github.com/connorshea/vglist/pull/399
[#400]: https://github.com/connorshea/vglist/pull/400
[#401]: https://github.com/connorshea/vglist/pull/401
[#411]: https://github.com/connorshea/vglist/pull/411
[#436]: https://github.com/connorshea/vglist/pull/436
[#438]: https://github.com/connorshea/vglist/pull/438
[#473]: https://github.com/connorshea/vglist/pull/473
[#474]: https://github.com/connorshea/vglist/pull/474
[#495]: https://github.com/connorshea/vglist/pull/495
[#506]: https://github.com/connorshea/vglist/pull/506
[#561]: https://github.com/connorshea/vglist/pull/561
[#572]: https://github.com/connorshea/vglist/pull/572
[#575]: https://github.com/connorshea/vglist/pull/575
[#577]: https://github.com/connorshea/vglist/pull/577
[#584]: https://github.com/connorshea/vglist/pull/584
[#598]: https://github.com/connorshea/vglist/pull/598
[#614]: https://github.com/connorshea/vglist/pull/614
[#615]: https://github.com/connorshea/vglist/pull/615
[#616]: https://github.com/connorshea/vglist/pull/616
[#617]: https://github.com/connorshea/vglist/pull/617
[#628]: https://github.com/connorshea/vglist/pull/628
[#630]: https://github.com/connorshea/vglist/pull/630
[#632]: https://github.com/connorshea/vglist/pull/632
[#638]: https://github.com/connorshea/vglist/pull/638
[#639]: https://github.com/connorshea/vglist/pull/639
[#640]: https://github.com/connorshea/vglist/pull/640
[#641]: https://github.com/connorshea/vglist/pull/641
[#652]: https://github.com/connorshea/vglist/pull/652
[#654]: https://github.com/connorshea/vglist/pull/654
[#656]: https://github.com/connorshea/vglist/pull/656
[#665]: https://github.com/connorshea/vglist/pull/665
[#667]: https://github.com/connorshea/vglist/pull/667
[#670]: https://github.com/connorshea/vglist/pull/670
[#678]: https://github.com/connorshea/vglist/pull/678
[#681]: https://github.com/connorshea/vglist/pull/681
[#697]: https://github.com/connorshea/vglist/pull/697
[#711]: https://github.com/connorshea/vglist/pull/711
[#712]: https://github.com/connorshea/vglist/pull/712
[#738]: https://github.com/connorshea/vglist/pull/738
[#747]: https://github.com/connorshea/vglist/pull/747
[#755]: https://github.com/connorshea/vglist/pull/755
[#756]: https://github.com/connorshea/vglist/pull/756
[#757]: https://github.com/connorshea/vglist/pull/757
[#758]: https://github.com/connorshea/vglist/pull/758
[#759]: https://github.com/connorshea/vglist/pull/759
[#760]: https://github.com/connorshea/vglist/pull/760
[#761]: https://github.com/connorshea/vglist/pull/761
[#778]: https://github.com/connorshea/vglist/pull/778
[#803]: https://github.com/connorshea/vglist/pull/803
[#811]: https://github.com/connorshea/vglist/pull/811
[#842]: https://github.com/connorshea/vglist/pull/842
[#852]: https://github.com/connorshea/vglist/pull/852
[#859]: https://github.com/connorshea/vglist/pull/859
[#860]: https://github.com/connorshea/vglist/pull/860
[#861]: https://github.com/connorshea/vglist/pull/861
[#884]: https://github.com/connorshea/vglist/pull/884
[#897]: https://github.com/connorshea/vglist/pull/897
[#917]: https://github.com/connorshea/vglist/pull/917
[#918]: https://github.com/connorshea/vglist/pull/918
[#960]: https://github.com/connorshea/vglist/pull/960
[#971]: https://github.com/connorshea/vglist/pull/971
[#987]: https://github.com/connorshea/vglist/pull/987
[#989]: https://github.com/connorshea/vglist/pull/989
[#990]: https://github.com/connorshea/vglist/pull/990
[#996]: https://github.com/connorshea/vglist/pull/996
[#1014]: https://github.com/connorshea/vglist/pull/1014
[#1021]: https://github.com/connorshea/vglist/pull/1021
[#1044]: https://github.com/connorshea/vglist/pull/1044
[#1123]: https://github.com/connorshea/vglist/pull/1123
[#1174]: https://github.com/connorshea/vglist/pull/1174
[#1181]: https://github.com/connorshea/vglist/pull/1181
[#1182]: https://github.com/connorshea/vglist/pull/1182
[#1185]: https://github.com/connorshea/vglist/pull/1185
[#1197]: https://github.com/connorshea/vglist/pull/1197
[#1198]: https://github.com/connorshea/vglist/pull/1198
[#1202]: https://github.com/connorshea/vglist/pull/1202
[#1212]: https://github.com/connorshea/vglist/pull/1212
[#1213]: https://github.com/connorshea/vglist/pull/1213
[#1218]: https://github.com/connorshea/vglist/pull/1218
[#1249]: https://github.com/connorshea/vglist/pull/1249
[#1262]: https://github.com/connorshea/vglist/pull/1262
[#1329]: https://github.com/connorshea/vglist/pull/1329
[#1331]: https://github.com/connorshea/vglist/pull/1331
[#1378]: https://github.com/connorshea/vglist/pull/1378
[#1392]: https://github.com/connorshea/vglist/pull/1392
[#1394]: https://github.com/connorshea/vglist/pull/1394
[#1403]: https://github.com/connorshea/vglist/pull/1403
[#1488]: https://github.com/connorshea/vglist/pull/1488
[#1501]: https://github.com/connorshea/vglist/pull/1501
[#1568]: https://github.com/connorshea/vglist/pull/1568
[#1649]: https://github.com/connorshea/vglist/pull/1649
[#1667]: https://github.com/connorshea/vglist/pull/1667
[#1668]: https://github.com/connorshea/vglist/pull/1668
[#1678]: https://github.com/connorshea/vglist/pull/1678
[#1684]: https://github.com/connorshea/vglist/pull/1684
[#1696]: https://github.com/connorshea/vglist/pull/1696
[#1712]: https://github.com/connorshea/vglist/pull/1712
[#1746]: https://github.com/connorshea/vglist/pull/1746
[#1747]: https://github.com/connorshea/vglist/pull/1747
[#1771]: https://github.com/connorshea/vglist/pull/1771
[#1806]: https://github.com/connorshea/vglist/pull/1806
[#1817]: https://github.com/connorshea/vglist/pull/1817
[#1895]: https://github.com/connorshea/vglist/pull/1895
[#1906]: https://github.com/connorshea/vglist/pull/1906
[#1907]: https://github.com/connorshea/vglist/pull/1907
