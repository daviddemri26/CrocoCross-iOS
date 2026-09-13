# CrocoCross 1.0 — App Store listing draft

English (U.S.) preparation copy, September 12, 2026. Nothing in this document has been submitted or published. Game Center configuration and server score read-back remain unverified; the online-ranking paragraph below is release copy to use only after the checks in [GAME-CENTER-SETUP.md](GAME-CENTER-SETUP.md) pass.

## Name

CrocoCross

## Subtitle

Bike Stunts & Weekly Trails

## Promotional text

Pick your rider, master the hills, and take on a new 4,000 m trail each week. Keep riding in Endless, with nine worlds to explore and no ads.

## Description

One more hill. One cleaner landing. One more ride.

CrocoCross is a motorcycle game about momentum, balance and the joy of finding your rhythm. Pick an animal rider, choose your scenery, and guide your bike across rolling trails.

Take on the weekly 4,000 m challenge with one life and no time limit. The trail changes every Monday at 00:00 UTC. Learn its jumps, land your flips, and try to reach the finish in your best run yet.

For a longer ride, jump into Endless. You have three lives to travel farther and build your best score.

Choose from 9 animal riders and 9 illustrated worlds, from desert canyons and snowy peaks to Paris and the clouds. Every rider shares the same physics: choose the style you love.

Two touch pedals put acceleration, braking and aerial balance under your thumbs. Hold a pedal and slide down for a lighter touch. Match the slope as you land; a flip counts only when you land safely.

Play Endless and weekly practice offline. Your settings and local records stay on your device. Pause and choose Keep riding during a run. Returning Home or leaving the app ends that ride; reopening starts at Home. Adjust music, engine sounds, effects and haptics to suit your ride.

Open Rankings to connect to Game Center and compare your best Endless score, weekly score and fastest weekly finish. Weekly rankings require a completed 4,000 m run started with an eligible Game Center challenge. Internet access is needed for online rankings; no separate CrocoCross account is required.

Free to play. No ads. No in-app purchases.

## Keywords

motocross,motorbike,offroad,hills,flips,jumps,animals,endless,offline,arcade

## Field limits

Verified draft counts: name 10/30 characters, subtitle 27/30, promotional text 141/170, description 1547/4000, keywords 76/100 bytes.

Count only the field text, excluding headings and these instructions. Name and subtitle must each fit within 30 characters. Promotional text permits 170 characters, description 4,000 characters, and keywords 100 bytes. The keyword draft uses ASCII, so its byte and character counts are identical. [Apple app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

Apple does not provide a “What's New” field for the first app version. Use the beta notes below for the initial TestFlight build. [Apple version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

## TestFlight — What to Test

This beta focuses on riding, touch controls, settings and the run lifecycle on iPhone and iPad. You can play without a CrocoCross account. If Game Center is not configured or the first weekly competition has not started, choose Weekly Challenge for local practice or choose Endless. Connection and leaderboard status appear in Rankings; gameplay has no PRACTICE status label.

Please try both pedals, lighter pressure by sliding down, jumps, safe flips and difficult landings. Check the one-life weekly challenge and three-life Endless mode. Use the Rider and World selectors, then Pause and Keep riding. Starting, restarting and Ride again must begin immediately, without confirmation. Returning Home or backgrounding the app must abandon the ride; relaunch must open Home with no Continue option. A temporary system interruption should pause the ride in memory. Check that personal records, rider/world selection and sound preferences remain.

Open Settings > Audio to check Play music, Playlist/One track mode, direct track selection, Mute all sound and the three volume sliders. Audio has no play/pause, next or previous transport buttons. Check haptics in Settings > General, headphones, the silent switch, and leaving the app during play. Report the device, iOS version, build number and steps that led to a problem; screenshots or a short recording are helpful.

Online leaderboard tests begin only after the team confirms Game Center setup and the weekly start time. At that point, open Rankings > Connect before starting a new ranked run. Finish a real weekly course and check its score and time in the leaderboards. Earlier guest/practice runs are not added retrospectively. A result from an expired week is not moved into the next week's ranking.

## App Review notes — draft

CrocoCross is a native motorcycle game for iPhone and iPad. No app account, demo credentials, purchase or subscription is required to play. Apple Game Center sign-in is optional and is used only for online competition.

To test offline gameplay, dismiss or decline optional Game Center sign-in, select Weekly Challenge or Endless, and start a ride. Weekly practice is 4,000 m with one life and no time limit. Endless starts with three lives. Use the right pedal to accelerate or lean back in the air; use the left pedal to brake or lean forward. Slide a held pedal downward to reduce its strength.

For online testing, open Rankings to connect to Game Center, start a new ranked weekly challenge after its configured opening time, and finish the course. Weekly score and fastest-finish entries are submitted only for completed courses. The two weekly boards open together each Monday at 00:00 UTC. Before the first occurrence opens, or when an eligible occurrence cannot be loaded, the app provides local practice.

Current preparation status: Game Center server configuration and real score read-back still need verification. Update this note with the verified opening time and results before submitting the release candidate. Do not present an unavailable online feature as ready for review.

Confirmed first weekly opening: [OWNER/RELEASE TEAM TO FILL — UTC DATE AND TIME]

## Owner details to complete before submission

- Support URL: [OWNER TO PROVIDE — PUBLIC HTTPS SUPPORT PAGE WITH REAL CONTACT DETAILS]
- Privacy policy URL: [OWNER TO PROVIDE — PUBLIC HTTPS POLICY FOR THIS IOS APP]
- App Review contact name: [OWNER TO CONFIRM]
- App Review contact email: [OWNER TO PROVIDE]
- App Review contact phone, including country code: [OWNER TO PROVIDE]
- TestFlight feedback email: [OWNER TO PROVIDE]
- Copyright holder and year: [OWNER TO CONFIRM]

These are intentional placeholders, not values to upload. Apple requires a support page with real contact information and a privacy policy URL for an iOS app. The in-app privacy screen does not supply a hosted URL. [Apple support URL requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), [privacy policy URL requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information).

## Evidence to attach to the release record

Capture screenshots from the candidate actually being submitted. Record completed device checks and Game Center score read-back separately from build or archive success. This draft makes no claim that the app is published, that Game Center is live, or that Duo has been tested. See [RELEASE.md](RELEASE.md) for the remaining release steps.
