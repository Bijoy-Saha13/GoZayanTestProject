# NOTES — Flight Results take-home

> ✏️ **Before submitting:** the brief asks for *your* account of the work. Sections marked ✏️ are drafted from the session log and must be checked and rewritten in your own words — especially which decisions were yours.

## 1. AI tool

- **Claude Code** (model: Claude Opus 5), in the Claude desktop app, with the iOS Simulator and an in-app browser for reading the Figma file.

## 2. How the AI was directed

Option A: the spec first, then one step per prompt, each checked before moving on. The commit history follows these steps.

| Step | Prompt (short) | Output | How it was checked |
|---|---|---|---|
| 1 | Read the brief and the codebase; write the requirements | `spec/REQUIREMENTS.md` v1: states, data mapping, MVVM + Coordinator rules, open decisions, audit of existing code, Definition of Done | Read against the PDF |
| 2 | Build the UI to the requirements | Figma captured into spec v2; UIKit screen in all four states on sample data | Every state, the dropdown, retry and taps run in the simulator; large Dynamic Type |
| 3 | Implement with the real API | Models + mapper, network rewrite, ViewModel, Coordinator; spec v3 records what changed | Live SerpApi call; simulator run against live data (success, sort, Learn more, error state) |
| 4 | Check the code against the spec and close the gaps | A 2-stop sample itinerary for the `success` stub, iPhone portrait only, light mode forced, iOS 17.0 target, spec v4 with the Definition of Done checked | Debug and Release builds; simulator on iOS 17.5 and 26.3 (all four states, the 2 Stop card, Learn more with the device in dark mode, a copy of the repo with no key) |

## 3. What had to be corrected or thrown away ✏️

**In the existing code (before the AI work)** — the network layer brought in from another project had real bugs (spec §11):
- `HTTPClient` built a `URLRequest` with method, headers and cache policy, then sent the bare URL, so none of them were used.
- A custom `URLSession.data(from:)` re-implemented an API Foundation already has.
- `try?` on decoding and `catch { .unknown }` hid every failure, so "offline" and "bad data" looked the same.
- Only 401 was handled; 429 (quota used up) — likely with a 100-search trial — was not.
- Caching inside the client had no expiry and used the API key as part of the cache key.
- `RequestError` imported UIKit and held user-facing copy.

All of it was rewritten (`Services/Network`).

**In the AI's own output, caught during review:**
- **The spec guessed wrong before the design was read.** It assumed the header shows airport codes, the carousel appears only with results, and multi-airline cards say "& more". Figma shows city names, a carousel while loading too, and "A + B". The spec was corrected (v2).
- **The brief's example request doesn't work.** `currency=BDT` returns `HTTP 400 "Unsupported BDT for currency."` The search was switched to USD.
- **The loading progress bar was invisible.** Its layer was sized before its parent had a width; it was moved into its own view.
- **Small UI mistakes.** "Starting from" appeared above "Price unavailable", the dimmed bar turned the yellow Filter button muddy, and the header subtitle truncated at large text sizes. All three were fixed.
- **A spec edit dropped a section separator.** It was caught while preparing commits.
- **Thrown away:** the DEBUG sample-data preview harness that drove the UI step, replaced by the real ViewModel and stub services.
- **Thrown away:** an AI-written unit test suite. I removed it because I don't write tests yet, and I didn't want to submit code I couldn't explain. Tests are optional extra credit.

✏️ *Add anything you changed, rejected or asked the AI to redo yourself.*

## 4. Architecture decisions ✏️

✏️ *Mark each row as yours, or as the AI's proposal that you accepted, and say why.*

| Decision | Reason |
|---|---|
| **MVVM + Coordinator split.** The ViewModel imports only Foundation, owns state and the API call, and reports out through `FlightResultsCoordinatorDelegate` and a state closure. `FlightResultsCoordinator` builds the screen and is the only place that presents anything. | Required by the brief; the ViewModel can be unit-tested with no UIKit and no Coordinator. |
| **Exactly four states, no idle.** `FlightResultsState` = `loading / success / empty / error`, and the ViewModel starts in `loading`. | Matches the brief and keeps the view logic small. |
| **HTTP 200 with no itineraries is `empty`, not `error`.** | SerpApi returns 200 plus an `"error"` message when Google finds nothing. |
| **DTOs separate from `FlightOffer`, with a pure mapper.** | The API shape can change without touching the UI, and the mapper is easy to test. |
| **Stops = `layovers.count`, falling back to legs − 1.** | Real non-stop results omit `layovers`. |
| **Duration from `total_duration`, never arrival − departure.** | The two times are local to different time zones. |
| **Times and dates as components (`LocalDateTime`, `CalendarDay`), not `Date`.** | The device time zone can never shift a displayed time. |
| **Sorting is a plain static function in the ViewModel.** It is stable, puts a missing price last, and the default is Cheapest. | The brief's extra credit; matches the design's label. |
| **A newer load supersedes an older one** (generation counter). | A slow response can't overwrite a newer state. |
| **Caching is a decorator over `HTTPClient`**, Debug only, and the cache key excludes `api_key`. | Saves quota without mixing concerns or writing the key to disk. |
| **Composition root in `AppDependencies`.** Stub and fixture services are chosen there. | One place decides what is real. |
| **UIKit with programmatic layout**, compositional layout with a diffable data source, and no third-party libraries. | The project was already UIKit; sort changes animate in place. |

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
