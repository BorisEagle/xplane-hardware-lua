# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add Saitek AV8R-01 OFF/A/B switch integration for the Zibo position lights,
  using direct Steady and Strobe assignments plus scripted OFF detection.
- Add Linux-native TCA Boeing four-lever throttle averaging for the Zibo
  737-800, replacing the previous Joystick Gremlin and vJoy chain.
- Add a manual Linux migration checklist for the eight active cockpit devices
  from the old X-Plane control profile.

## [1.0.1] - 2026-09-09

### Fixed

- Apply an immediate one-foot MINS step on each direction press, restoring
  fine adjustment without SimAppPro when X-Plane assigns the buttons to Lua.
- Preserve the existing 10 ft / 100 ft acceleration stages and immediate stop
  on release.
- Update setup instructions to prevent parallel SimAppPro MINS input.

## [1.0.0] - 2026-08-12

### Added

- Added staged captain-side MINS acceleration for the WINWING WINCTRL 3N PDC L
  with the Zibo 737-800 in X-Plane 12.
- Preserved SimAppPro fine adjustment for short holds.
- Added controlled 10 ft steps after 0.30 seconds.
- Added controlled 100 ft steps after 1.50 seconds.
- Added immediate stopping on release without queued movement.
