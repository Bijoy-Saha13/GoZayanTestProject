# NOTES — Flight Results take-home

## 1. AI tool

- **Claude Code** (model: Claude Opus 5), in the Claude desktop app, with the iOS Simulator and an in-app browser for reading the Figma file.
- This file and the spec were also drafted by Claude Code from the work sessions. I read them and checked them against the brief and the app.

## 2. How the AI was directed

Option A: the spec first, then one step per prompt, each checked before moving on. The commit history follows these steps.

| Step | Prompt (short) | Output | How it was checked |
|---|---|---|---|
| 1 | Read the brief and the codebase; write the requirements | `spec/REQUIREMENTS.md` v1: states, data mapping, MVVM + Coordinator rules, open decisions, audit of existing code, Definition of Done | Read against the PDF |
| 2 | Build the UI to the requirements | Figma captured into spec v2; UIKit screen in all four states on sample data | Every state, the dropdown, retry and taps run in the simulator; large Dynamic Type |
| 3 | Implement with the real API | Models + mapper, network rewrite, ViewModel, Coordinator; spec v3 records what changed | Live SerpApi call; simulator run against live data (success, sort, Learn more, error state) |
| 4 | Check the code against the spec and close the gaps | A 2-stop sample itinerary for the `success` stub, iPhone portrait only, light mode forced, iOS 17.0 target, spec v4 with the Definition of Done checked | Debug and Release builds; simulator on iOS 17.5 and 26.3 (all four states, the 2 Stop card, Learn more with the device in dark mode, a copy of the repo with no key) |

## 3. What had to be corrected or thrown away

The old network layer had real bugs: it built a request and then sent the bare URL, hid every error with `try?`, didn't handle 429, and cached responses with the API key in the cache key. It was rewritten. In the AI's work I caught design points it missed against Figma (city names in the header, the carousel while loading, "A + B" airline names), UI bugs in the simulator (an invisible progress bar, "Starting from" above "Price unavailable", a cut-off header), and a currency SerpApi rejects (BDT, switched to USD). A final check against the spec found more gaps: no way to show "2 Stop", iPad and landscape still enabled, dark mode not handled, and an iOS target too new for older Xcode. I threw away the preview harness used for the UI step and the AI-written unit tests, because I don't write tests yet and I don't want to submit code I can't explain.

## 4. Architecture decisions

My decisions were UIKit, keeping MVVM + Coordinator strict (the ViewModel imports only Foundation and never knows the Coordinator), and an iterative approach: spec first, then the UI, then the real API, then a check against the spec, reviewing each step before the next. Claude Code proposed the details inside that structure, such as the four states, DTOs with a separate mapper, the cache wrapper, times without time zones and the generation counter. I reviewed them and kept them; the reasons are in the spec (§12 and §17).

## 5. Decisions on the open points

| Open point | Choice | Why |
|---|---|---|
| Route and date | DAC → BKK, 1 adult, **30 days from today** | Never a past date (the brief's example date has already passed) |
| Where the API key lives | Git-ignored `GoZayanProject/Config/Secrets.plist` | Never committed; without it, Debug builds use the bundled fixture |
| Price format | `USD 297` — code, space, grouped whole amount | Matches the design's `BDT 70,129` pattern; BDT itself is rejected by SerpApi |
| What empty looks like | Icon, "No flights found", "Try a different date or route.", **Search again** | Not in Figma; uses the same tokens as the rest of the screen |
| Merging `best_flights` and `other_flights` | Best first, then other, each in API order, then sorted (default Cheapest) | Google doesn't duplicate across the two arrays; `source` is kept on the model |
| Where the promo carousel goes | After the 2nd card (after the last if there are fewer); also after the 2nd skeleton while loading | Matches Figma; visible without pushing the first results off screen |
| Flight with no price | Kept, shown as "Price unavailable", sorted last | Hiding real flights is worse than showing them without a price |
| Header in empty and error states | Always shown | It's built from the search, not the response, so the user still sees what was searched |
| Flights with several airlines | Names joined with " + ", cut off at the end if too long | Matches Figma ("Air Arabia + US Bangla Airlin…") |
| Date strip | Hard-coded fares for 3 days either side of the search date; taps ignored | The brief asks for dummy data; the highlighted chip always matches the header date |
| Tapping a flight card | Reported to the Coordinator, which does nothing | The brief defines the delegate but no details screen |
| Promo images | Bundled in the app | Dummy data; no image loading needed |
| How gozayaan.com opens | In-app Safari sheet (`SFSafariViewController`) presented by the Coordinator | Keeps the user in the app, and navigation stays in the Coordinator |
| Devices and iOS version | iPhone, portrait only, iOS 17.0+ | The design is a portrait phone screen; 17.0 is the oldest iOS the app was actually run on |
| Dark mode | Forced light | Figma has no dark design |
| Seeing every state | Debug launch argument `-FlightsStubState` | Empty and error can't be produced on demand from the real API |

## 6. Running it

- **Requirements:** Xcode 26 (built with 26.3) and an iPhone simulator on iOS 17.0 or later.
- **API key:** copy `Secrets.example.plist` to `GoZayanProject/Config/Secrets.plist` and add your SerpApi key. Without it, Debug builds show the bundled real response.
- **See each state:** in *Edit Scheme → Run → Arguments*, enable one of `-FlightsStubState loading`, `success`, `empty` or `error`. `-FlightsBypassCache YES` skips the 24 h development cache.
- **See "2 Stop":** the captured DAC → BKK response has no 2-stop flight, so `-FlightsStubState success` adds one hand-made itinerary (DAC → CCU → DEL → BKK, USD 341) from `Resources/StubMultiStopItinerary.json`. It goes through the same decoder and mapper as live data.

## 7. Known limitations

- **The key can be extracted.** A key inside an app bundle can be pulled out of the binary; a production app would call its own backend.
- **Approximate colours and font.** Colours were matched by eye (Figma inspect needs an account), and SF Pro stands in for the design's font. All tokens are in `Theme.swift`.
- **Decorative controls.** Edit, Filter, the price-trend badge, the back chevron and "Get Points" do nothing. There is no flight details screen.
- **Dummy data.** Date-strip fares and promos are hard-coded, as the brief asks.
- **No unit tests** (optional extra credit, not included).
- **iPhone, portrait, light mode only.** The design has no landscape, iPad or dark variants.
- **The 2-stop flight is sample data.** It only appears with `-FlightsStubState success`.
