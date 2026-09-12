# Contributing to CrocoCross

Start with the [README](README.md) and [development guide](docs/DEVELOPMENT.md). Discuss substantial gameplay or architectural changes in an issue before implementation. Repository access does not grant a redistribution license; see [RIGHTS.md](RIGHTS.md).

## Local workflow

1. Create a focused branch, preferably `codex/<short-description>`.
2. Make the change and update the relevant documentation.
3. If you add or remove app/UI-test Swift files, run `python3 scripts/generate-project.py` and include the generated Xcode project.
4. Run `swift test --disable-sandbox` and the unsigned simulator build from the README. For persistence changes, run the harness in the development guide.
5. Open a pull request describing behavior, completed checks and release impact. Use Conventional Commits, for example `fix(physics): preserve traction on shallow slopes`.

For visible changes, exercise affected flows on both iPhone and iPad and attach representative captures. For audio, touch handling or lifecycle changes, distinguish simulator checks from physical-device evidence. Do not report unperformed checks as passing.

## Engineering boundaries

- Keep simulation authority in `CrocoCrossCore`; SpriteKit renders simulation state.
- Preserve deterministic terrain and gameplay randomness independently of decoration.
- Version physics/course rules and leaderboard IDs when scores become incomparable.
- Preserve local saves and account ownership of pending Game Center scores.
- Keep offline practice available without an account or network.
- Keep the original web project's services and database independent.
- Never commit signing credentials, profiles, local account data, generated build output or unlicensed assets.

GitHub CI checks core behavior, storage and the simulator build. It does not perform device gameplay validation, configure live Game Center, upload to TestFlight or submit an App Store release.
