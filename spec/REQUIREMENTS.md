# Flight Results — Requirements & Technical Spec

> **Source of truth:** *iOS Take-Home Task — Flight Results* (GoZayaan, PDF, 6 pages) + SerpApi docs + Figma reference.
> **Approach:** Option A — this spec is written **before** any AI prompting and is committed first, so the git history shows the spec preceding the implementation.
> **Status:** v3 · 2026-09-15 — Figma captured (§13); implemented, with changes recorded in §17

---

## 0. How to read this document

### 0.1 Priority

| Tag | Meaning |
|---|---|
| **MUST** | Stated as mandatory in the task PDF. Missing it fails the task. |
| **SHOULD** | Not stated word-for-word, but directly implied by the scoring table or the design. Treat as required. |
| **MAY** | Optional extra credit. Only adds to the score. |

### 0.2 Source tags

| Tag | Meaning |
|---|---|
| `[PDF p.N]` | Quoted or paraphrased from the task PDF, page N. |
| `[API]` | From SerpApi documentation (serpapi.com/google-flights-api, /google-flights-results, /api-status-and-error-codes). |
| `[FIGMA]` | Must be taken from the Figma file. **Not yet captured — see §13.** |
| `[DECISION]` | Left open on purpose by the task [PDF p.6]. Our choice + reason is in §12 and must be repeated in `NOTES.md`. |
| `[AUDIT]` | Found while reviewing the existing codebase (§11). |

Every requirement has an ID (`FR-`, `ST-`, `DATA-`, `ARCH-`, …) so commits, tests and `NOTES.md` can reference it.

---

## 1. Goal

Build **one screen — Flight Results — in all four of its states** (loading, success, empty, error), using an AI coding assistant, with **MVVM + Coordinator** architecture, real data from the **SerpApi Google Flights API**, plus a little hard-coded dummy data. `[PDF p.1–2]`

The evaluators care as much about **how the AI was directed and reviewed** as about the app. `[PDF p.1]`

### 1.1 Hard facts from the brief

| # | Fact | Source |
|---|---|---|
| F1 | One screen only: Flight Results, all four states. | `[PDF p.1]` |
| F2 | Architecture: MVVM + Coordinator. "Required, not a suggestion." | `[PDF p.1]` |
| F3 | UI framework: UIKit or SwiftUI (our choice). | `[PDF p.1]` |
| F4 | Data: real SerpApi flight results + a little dummy data. | `[PDF p.1]` |
| F5 | Time: 2–3 days. **Send link within 3 days of receiving the task.** If blocked, email *before* the deadline. | `[PDF p.1, p.5]` |
| F6 | Walkthrough call after submission — must be able to explain every decision. | `[PDF p.1, p.6]` |
| F7 | Questions: reply to the HR email, CC `rejaul.shawon@gozayaan.com` and `tawhid.alam@gozayaan.com`. Reply within one working day. | `[PDF p.6]` |

### 1.2 Out of scope (do NOT build)

- Edit/search flow (Edit button is decorative). `[PDF p.2]`
- Date-strip tap behaviour (taps ignored). `[PDF p.2]`
- Round trip / multi-city. `[PDF p.3]`
- `departure_token` / `booking_token` flows (return legs, booking). `[PDF p.3]`
- Flight detail screen. The only real navigation is **Learn more → gozayaan.com**. `[PDF p.2]`

---

## 2. Deliverables `[PDF p.5]`

| ID | Deliverable | Priority | Verify |
|---|---|---|---|
| DEL-01 | **One git repo** pushed to GitHub, GitLab or Bitbucket; link sent. | MUST | Repo URL opens; clone builds. |
| DEL-02 | `/spec` folder at repo root containing the spec (Markdown or plain text). This file lives there. | MUST | `ls spec/` shows this spec. |
| DEL-03 | Xcode project **at the root of the repo**. | MUST | `GoZayanProject.xcodeproj` at repo root. ✅ already true |
| DEL-04 | `NOTES.md` at repo root: (a) which AI tool was used, (b) what had to be corrected or thrown away, (c) which architectural decisions were our own. | MUST | File exists and has all three sections. |
| DEL-05 | **Keep commit history** — they read it. Small, meaningful commits; no single squash. | MUST | `git log` shows incremental steps; spec commit precedes feature code. |
| DEL-06 | Sent within 3 days of receiving the task. | MUST | — |
| DEL-07 | Reviewers can build and run the app without guessing (README/NOTES section: how to add the API key, how to see each state). | SHOULD | Fresh clone → follow notes → app runs. |
| DEL-08 | **No API key committed** anywhere in history. | MUST (security) | `git log -p \| grep -i api_key` shows only placeholders. |

---

## 3. Screen composition `[PDF p.2]`

Top-to-bottom layout (exact visuals `[FIGMA]`; dates/fares below are illustrative):

```
┌───────────────────────────────────────┐
│ Route header                          │  FR-01
│  DAC → BKK            [Edit]          │
│  Wed, 14 Oct · 1 Traveller · One Way  │
├───────────────────────────────────────┤
│ Date & price strip (horizontal scroll)│  FR-02
│ [Tue 13 Oct][Wed 14 Oct*][Thu 15 Oct] │
│ [BDT 70,129][BDT 37,400][BDT 41,250]  │
├───────────────────────────────────────┤
│ Sort control  "Cheapest ▾"            │  EXT-01 (design element)
├───────────────────────────────────────┤
│ Content area — depends on state:      │
│  loading → skeleton shimmer cards     │  FR-03
│  success → flight cards               │  FR-04
│            + discount carousel        │  FR-05
│            (between cards)            │
│  empty   → empty view                 │  ST-03
│  error   → error view + retry         │  ST-04
└───────────────────────────────────────┘
```

### 3.1 Functional requirements

| ID | Requirement | Priority | Verify |
|---|---|---|---|
| **FR-01** | **Route header** shows: origin → destination (city names, e.g. "Dhaka - Bangkok", per Figma), the date, passenger count, the text **"One Way"**, and an **Edit** button. Edit may be decorative (no action). Figma also shows a back chevron — decorative, the screen is the app root. | MUST `[PDF p.2]` | Visual check against Figma; values come from `FlightSearchRequest`, not from the API response. |
| FR-01a | Header content is built from `FlightSearchRequest`, so it is visible and correct in **all four states** (including error/empty, when there is no response). | SHOULD `[DECISION D-08]` | Force error state → header still shows route/date/pax. |
| **FR-02** | **Date & price strip**: horizontal row of day chips, each showing a day label (e.g. `Sun 08 Feb`) and a fare under it (e.g. `BDT 70,129`). The **selected day is highlighted**. Data is **hard-coded dummy data**. **Taps are ignored.** **Must scroll horizontally.** | MUST `[PDF p.2]` | ≥7 chips so it overflows and scrolls; tapping a chip changes nothing (no state change, no reload, no highlight change); selected chip matches search date. |
| FR-02a | Selected chip is scrolled into view on first display. | SHOULD | Launch → highlighted chip visible without manual scroll. |
| **FR-03** | **Loading skeletons**: shimmer placeholder cards shown while results load. Layout mirrors the real flight card. | MUST `[PDF p.2, p.6]` | Launch with slow/stubbed service → shimmer cards animate; matches Figma *"Flight Result, loading"*. |
| FR-03a | Shimmer respects **Reduce Motion** (static placeholders when enabled). | SHOULD | Settings → Reduce Motion ON → no animation. |
| **FR-04** | **Flight card** shows: **airline**, **departure time**, **arrival time**, **duration**, **stops** (`Non-Stop` / `1 Stop` / `2 Stop`), **the two airport codes** (origin, final destination), and the **starting price**. | MUST `[PDF p.2]` | Card for a known fixture shows every field with the formats in §6.5. |
| FR-04a | Tapping a flight card reports `didSelectFlight(_ offer: FlightOffer)` via the delegate (§8.3). No screen is pushed. | SHOULD `[PDF p.4]` `[DECISION D-11]` | Unit test: VM calls delegate with the tapped offer. |
| **FR-05** | **Discount carousel**: promo cards scrolling **sideways**, placed **between the flight cards**. Each promo has an **image**, a **title** and a **Learn more** link. Dummy data: `(image, title, URL)`. | MUST `[PDF p.2]` | Success state shows horizontally scrolling promo row inside the vertical list. |
| **FR-06** | **Learn more** opens **gozayaan.com** **through the Coordinator** — the only real navigation in the task. The View and ViewModel never open URLs or present controllers themselves. | MUST `[PDF p.2]` | Tap Learn more → gozayaan.com opens; code search: no `UIApplication.shared.open` / `SFSafariViewController` outside the Coordinator. |
| FR-07 | Carousel is placed after the **2nd** flight card. If there are fewer than 2 offers, it is placed after the last card. Also shown while loading, after the 2nd skeleton (Figma loading frame). | SHOULD `[DECISION D-06]` `[FIGMA]` | 1 offer → carousel after card 1; 5 offers → after card 2; loading → after skeleton 2; empty/error → no carousel. |
| FR-08 | Screen matches the Figma frames **"Flight Result, loading"** and **"Flight Result, with results"** (spacing, typography, colours, corner radius, icons). | MUST `[PDF p.6]` `[FIGMA]` | Side-by-side screenshot comparison. |

---

## 4. Screen states `[PDF p.2, p.4, p.6]`

Exactly four states. **No fifth "idle" state** — the ViewModel starts in `loading`.

```swift
enum FlightResultsState: Equatable {
    case loading
    case success(FlightResultsContent)   // offers (already sorted) + promos + selected sort
    case empty
    case error(FlightResultsError)       // user-presentable error kind
}
```

### 4.1 State definitions

| ID | State | Entered when | UI | Priority |
|---|---|---|---|---|
| **ST-01** | `loading` | Initial state; and on every (re)load / retry. | Header + date strip visible (fares shimmer). Content area: progress bar + "Hang tight!" message, 2 skeleton cards, promo carousel, 2 skeleton cards (Figma). Sort control inactive (not dimmed, as in Figma). | MUST |
| **ST-02** | `success` | Request succeeded (HTTP 2xx), decoded, and mapping produced **≥ 1** valid `FlightOffer`. | Flight cards + carousel (FR-07). Sort control enabled. | MUST |
| **ST-03** | `empty` | Request succeeded (HTTP 2xx), but mapping produced **0** valid offers. Includes: both arrays missing, both arrays empty, SerpApi's 200-with-`"error": "…hasn't returned any results…"`, all itineraries invalid (§6.4). | Icon + title "No flights found" + subtitle suggesting another date/route + **"Search again"** button that reloads. Sort control disabled. No carousel. `[DECISION D-05]` | MUST |
| **ST-04** | `error` | Transport failure, non-2xx status, `search_metadata.status == "Error"`, decode failure, or missing API key without fixture fallback. | Icon + title "Something went wrong" + message for the error kind (§4.3) + **"Try again"** button that reloads. Sort control disabled. No carousel. | MUST |

> ⚠️ **Awkward case (verified in SerpApi docs):** when Google Flights returns no results, SerpApi still responds **HTTP 200** with `search_metadata.status = "Success"` and a top-level `"error"` string. This **must map to `empty`, not `error`**. Do not branch on the exact error text (it can change); branch on "HTTP 2xx and zero valid offers". `[API]`

### 4.2 Transitions

```
            load()
 (init) ──► loading ──┬── ≥1 offer ─────► success ──(pull/retry/sort)──┐
                      ├── 0 offers ─────► empty ──── "Search again" ───┤
                      └── failure ──────► error ──── "Try again" ──────┤
                                                                       ▼
                                                                    loading
 success ── changeSort(_) ──► success (same offers, re-sorted, no network)
```

| ID | Rule | Priority | Verify (unit test) |
|---|---|---|---|
| ST-T1 | `init` → state is `.loading` before any call. | MUST | Assert initial state. |
| ST-T2 | `load()`: `loading → success` when service returns offers. | MUST `[PDF p.5]` | Mock service → states observed `[.loading, .success]`. |
| ST-T3 | `load()`: `loading → empty` when service returns 0 offers. | MUST `[PDF p.5]` | Mock → `[.loading, .empty]`. |
| ST-T4 | `load()`: `loading → error` when service throws. | MUST `[PDF p.5]` | Mock → `[.loading, .error(kind)]`. |
| ST-T5 | Retry from `error` or `empty` goes back through `loading`. | SHOULD | Mock fails then succeeds → `[.loading, .error, .loading, .success]`. |
| ST-T6 | Calling `load()` while a load is in flight **cancels** the previous task; a stale response can never overwrite a newer state. | SHOULD | Mock with controllable delay; first response arriving late is ignored. |
| ST-T7 | Changing sort in `success` re-emits `success` with re-ordered offers and **does not** call the service. | MAY (EXT-01) | Mock call count stays 1. |
| ST-T8 | State changes are delivered on the **main actor**. | SHOULD | VM is `@MainActor`. |
| ST-T9 | Every state change is emitted exactly once to the view (no duplicate emissions of identical state). | SHOULD | Recorded states contain no consecutive duplicates. |

### 4.3 Error kinds → user message

```swift
enum FlightResultsError: Equatable {
    case offline          // URLError.notConnectedToInternet, .networkConnectionLost, .timedOut
    case unauthorized     // HTTP 401 / 403 — bad or missing API key
    case quotaExceeded    // HTTP 429 — hourly limit or out of searches
    case server           // HTTP 5xx, other non-2xx, search_metadata.status == "Error"
    case invalidResponse  // decoding failed
}
```

| Kind | Title | Message (final copy may follow Figma/brand tone) |
|---|---|---|
| offline | No internet connection | Check your connection and try again. |
| unauthorized | Couldn't load flights | The flight service rejected our request. |
| quotaExceeded | Too many searches | Please try again later. |
| server | Something went wrong | We couldn't load flights right now. |
| invalidResponse | Something went wrong | We received an unexpected response. |

- ERR-01 (MUST): Raw technical errors, URLs, status codes and **never the API key** are shown to the user. Log them in DEBUG only.
- ERR-02 (SHOULD): Messages are defined in the ViewModel/presentation layer (Foundation only), not in the network layer, and not in `RequestError`.

---

## 5. Data source — SerpApi `[PDF p.3]` `[API]`

### 5.1 Request

| ID | Requirement | Priority |
|---|---|---|
| DATA-01 | Endpoint: `GET https://serpapi.com/search?engine=google_flights` | MUST |
| DATA-02 | One-way search: `type=2` (1 = round trip is the API default, so `type` **must** be sent). | MUST |
| DATA-03 | Params sent: `engine=google_flights`, `departure_id`, `arrival_id`, `outbound_date` (`YYYY-MM-DD`), `type=2`, `currency`, `hl=en`, `adults`, `api_key`. | MUST |
| DATA-04 | Do **not** send `return_date` (one-way). Ignore `departure_token` and `booking_token` in responses. | MUST |
| DATA-05 | `outbound_date` must be **today or later** — a past date makes the search fail. The PDF example date `2026-02-15` is already in the past (today is 2026-09-14), so it **cannot** be used as-is. | MUST `[DECISION D-01]` |
| DATA-06 | All query values are built with `URLComponents`/`URLQueryItem` (no string concatenation). | SHOULD |

`FlightSearchRequest` (Model, `Codable`, `Equatable`, `Sendable`) `[PDF p.4]`:

```swift
struct FlightSearchRequest: Codable, Equatable, Sendable {
    let departureID: String      // "DAC"
    let arrivalID: String        // "BKK"
    let outboundDate: Date       // serialised as yyyy-MM-dd
    let adults: Int              // 1
    let currency: String         // "BDT"
    let tripType: TripType       // .oneWay (raw value 2)
}
```

### 5.2 API key `[PDF p.3, p.6]`

| ID | Requirement | Priority |
|---|---|---|
| KEY-01 | Key is **never** hard-coded in Swift and **never** committed. | MUST |
| KEY-02 | Key lives in `Config/Secrets.xcconfig` (git-ignored) → build setting `SERPAPI_API_KEY` → Info.plist entry `SerpApiKey = $(SERPAPI_API_KEY)` → read once via `Bundle.main` by an `APIKeyProvider` injected into the service. | SHOULD `[DECISION D-02]` |
| KEY-03 | `Config/Secrets.example.xcconfig` is committed with a placeholder and a comment explaining setup. | SHOULD |
| KEY-04 | Full request URLs (which contain `api_key`) are never logged or shown. | MUST |
| KEY-05 | If the key is missing, DEBUG builds fall back to the bundled fixture response (§5.4) so reviewers can run the app without a key; this is stated in `NOTES.md`. | SHOULD `[DECISION D-02]` |
| KEY-06 | `NOTES.md` states the limitation: a key shipped inside an app binary is extractable; production would proxy through a backend. | SHOULD |

### 5.3 Quota & caching `[PDF p.3]` `[API]`

Free trial ≈ **100 searches**. The PDF explicitly says to **cache responses locally while developing**.

| ID | Requirement | Priority |
|---|---|---|
| CACHE-01 | DEBUG builds cache the **raw JSON** of successful responses on disk (`Caches/`), keyed by a hash of the request parameters **excluding `api_key`**. | MUST `[PDF p.3]` |
| CACHE-02 | Cache TTL in DEBUG: 24 h (configurable). A launch argument (`-FlightsBypassCache`) forces a live request. | SHOULD |
| CACHE-03 | Caching is a decorator (`CachingFlightSearchService` wrapping the live service) — not mixed into `HTTPClient`. | SHOULD `[AUDIT A-03]` |
| CACHE-04 | Error responses and non-2xx responses are **not** cached. | MUST |
| CACHE-05 | Tests never hit the live API; they use fixtures + mocks. | MUST `[PDF p.5]` |

Note: SerpApi also caches identical queries server-side for 1 h and those cached searches are free `[API]`. Our local cache is still required (works offline, survives > 1 h, and is what the brief asks for).

### 5.4 Fixtures

| ID | Requirement | Priority |
|---|---|---|
| FIX-01 | Capture **one real response** (DAC→BKK) and commit it as `FlightResultsFixture.json` (app bundle for DEBUG fallback, and test bundle). Scrub anything account-specific before committing. | SHOULD |
| FIX-02 | Hand-made fixtures for tests: non-stop, 1-stop, **2-stop multi-leg**, missing `layovers` key, missing `best_flights` key, missing `price`, overnight arrival, empty 200-with-`error`, malformed JSON. | SHOULD (MAY for tests) |

---

## 6. Data model & mapping `[PDF p.3–5]`

> "Flattening it into your own `FlightOffer` … is a real part of the task, and something we look at closely." `[PDF p.4]`

### 6.1 Layers

```
SerpApi JSON ──decode──► DTOs (Codable, mirror API, all optional where API may omit)
             ──map─────► FlightOffer (domain, flat, UI-agnostic)
             ──format──► FlightCardViewData (strings for the cell) — built by ViewModel/formatter
```

DTOs and domain models are **separate types**. Views never see DTOs.

### 6.2 DTOs (response shape) `[API]`

Only fields we use are decoded; unknown keys are ignored by `Codable` automatically.

```swift
struct FlightSearchResponseDTO: Decodable {
    let searchMetadata: SearchMetadataDTO?      // search_metadata
    let bestFlights: [ItineraryDTO]?            // best_flights   — MAY BE ABSENT
    let otherFlights: [ItineraryDTO]?           // other_flights  — MAY BE ABSENT
    let error: String?                          // present on 200 "no results"
}

struct SearchMetadataDTO: Decodable { let status: String? }   // "Success" | "Processing" | "Queued" | "Error"

struct ItineraryDTO: Decodable {
    let flights: [FlightLegDTO]?                // one entry per leg
    let layovers: [LayoverDTO]?                 // MAY BE ABSENT for non-stop
    let totalDuration: Int?                     // total_duration, minutes
    let price: Int?                             // MAY BE ABSENT
    let type: String?                           // "One way"
    let airlineLogo: String?                    // airline_logo
}

struct FlightLegDTO: Decodable {
    let departureAirport: AirportDTO?           // departure_airport
    let arrivalAirport: AirportDTO?             // arrival_airport
    let duration: Int?                          // minutes
    let airline: String?
    let airlineLogo: String?                    // airline_logo
    let flightNumber: String?                   // flight_number
    let overnight: Bool?
}

struct AirportDTO: Decodable { let id: String?; let name: String?; let time: String? }   // time "yyyy-MM-dd HH:mm"
struct LayoverDTO: Decodable { let id: String?; let name: String?; let duration: Int?; let overnight: Bool? }
```

- DATA-10 (MUST): Use `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` **or** explicit `CodingKeys` — pick one and use it consistently.
- DATA-11 (MUST): Missing `best_flights`, `other_flights` or `layovers` keys must **not** fail decoding.
- DATA-12 (MUST): A decoding failure is surfaced as `.invalidResponse` — never silently swallowed with `try?` `[AUDIT A-04]`.

### 6.3 Domain model

```swift
struct FlightOffer: Equatable, Hashable, Sendable, Identifiable {
    let id: String                 // stable: see MAP-10
    let airlineName: String
    let airlineLogoURL: URL?
    let originCode: String         // first leg departure_airport.id
    let destinationCode: String    // last  leg arrival_airport.id
    let departTime: LocalDateTime  // first leg departure time (airport-local wall clock)
    let arriveTime: LocalDateTime  // last  leg arrival time   (airport-local wall clock)
    let durationMinutes: Int       // total_duration
    let stops: Int                 // 0, 1, 2, …
    let layoverCodes: [String]     // e.g. ["KUL", "SIN"] (optional display)
    let price: Int?                // in request currency; nil = unavailable
    let currency: String           // from request
    let source: Source             // .best | .other (keeps API grouping)
}
```

The PDF calls the model `Codable` `[PDF p.4]`: `FlightOffer` and `FlightSearchRequest` conform to `Codable` (useful for the debug cache / fixtures); DTOs are `Decodable`.

### 6.4 Mapping rules — `FlightOfferMapper` (pure, Foundation-only, unit-tested)

| ID | Rule | Priority |
|---|---|---|
| MAP-01 | **One list:** result = `best_flights` (API order) followed by `other_flights` (API order). Missing array = `[]`. | MUST `[DECISION D-04]` |
| MAP-02 | **Stops** = `layovers.count` when `layovers` is present; otherwise `max(flights.count − 1, 0)`. A 3-leg itinerary with 2 layovers → `2`. | MUST `[PDF p.5]` |
| MAP-03 | **Stops label**: `0` → `Non-Stop`, `1` → `1 Stop`, `n ≥ 2` → `"\(n) Stop"` (exact wording from the brief: `2 Stop`, not "2 Stops"). | MUST `[PDF p.2]` |
| MAP-04 | **departTime** = `flights.first.departure_airport.time`; **arriveTime** = `flights.last.arrival_airport.time`. Never the first leg's arrival. | MUST |
| MAP-05 | **originCode** = `flights.first.departure_airport.id`; **destinationCode** = `flights.last.arrival_airport.id`. | MUST |
| MAP-06 | **Duration** = `total_duration`. If absent, fall back to `sum(flights.duration) + sum(layovers.duration)`. **Never** compute it as arrival − departure (times are in different local time zones). | MUST |
| MAP-07 | **Airline** = first leg's `airline`. If legs have more than one distinct airline, join the distinct names in leg order with `" + "` (Figma: "Air Arabia + US Bangla Airlin…", tail-truncated by the view). Logo = itinerary `airline_logo`, else first leg's. | SHOULD `[DECISION D-09]` `[FIGMA]` |
| MAP-08 | **Price** = `price`. If missing, keep the offer with `price = nil` (displayed as "Price unavailable", sorted last). | SHOULD `[DECISION D-07]` |
| MAP-09 | **Invalid itineraries are dropped** (not crashed on): `flights` missing/empty, or first departure / last arrival airport id or time missing/unparseable. | MUST |
| MAP-10 | **id** = deterministic from content: joined leg `flight_number`s + departure time (+ index as tiebreak). Needed for diffable data source; must be unique within a result. | SHOULD |
| MAP-11 | **Times are wall-clock local airport times with no time zone** (`"2026-02-15 12:30"`). Parse with `en_US_POSIX` locale and a **fixed** time zone (UTC) and format with the **same** fixed zone, so the displayed time never shifts with the device time zone. | MUST |
| MAP-12 | **Next-day arrival**: if arrival calendar date > departure calendar date, expose the day difference; the card shows `+1Day` / `+2Day` as a red superscript after the arrival time. | MUST `[FIGMA]` |

### 6.5 Display formatting (presentation layer, Foundation-only)

| ID | Field | Format | Example |
|---|---|---|---|
| FMT-01 | Price | `"<CUR> <grouped integer>"`, no decimals, grouping separator fixed to `,` (set explicitly, not taken from device locale) — matches brief sample | `BDT 37,400` `[PDF p.2]` `[DECISION D-03]` |
| FMT-02 | Duration | `Xh Ym`; omit zero parts | `280` → `4h 40m`; `120` → `2h`; `45` → `45m` |
| FMT-03 | Time | `HH:mm` (24 h) unless Figma shows 12 h | `12:30` `[FIGMA]` |
| FMT-04 | Header date | `dd MMM, yyyy` | `14 Oct, 2026` `[FIGMA]` |
| FMT-05 | Strip chip date | `EEE dd MMM` | `Sun 08 Feb` `[PDF p.2]` |
| FMT-06 | Passengers | person icon + zero-padded count | `👤01` `[FIGMA]` |
| FMT-07 | Formatters are cached (not created per cell) and injected, so tests are locale-independent. | SHOULD |

---

## 7. Dummy data `[PDF p.1–2]`

| ID | Requirement | Priority |
|---|---|---|
| DUM-01 | **Date strip**: hard-coded list of ≥ 7 fares (e.g. `[70129, 52300, 37400, 41250, 39900, 45600, 48000]` BDT). Chip dates are generated relative to the search date (search date − 3 … + 3) so the highlighted chip always equals the header date. | MUST `[DECISION D-10]` |
| DUM-02 | **Promos**: hard-coded list of ≥ 3 items `(image, title, url)`, all URLs pointing to `https://gozayaan.com` (paths allowed). | MUST `[PDF p.2]` |
| DUM-03 | Promo images are **bundled assets** (no network dependency, no third-party image loader). | SHOULD `[DECISION D-12]` |
| DUM-04 | Dummy data is provided through a protocol (`PromoProviding`, `FareCalendarProviding`) injected into the ViewModel — not hard-coded inside the View or ViewModel body. | SHOULD |

---

## 8. Architecture — MVVM + Coordinator `[PDF p.1, p.4]`

### 8.1 Layer ownership

| Layer | Owns | Must NOT | Priority |
|---|---|---|---|
| **Model** | `Codable` structs mapped from the API (`FlightOffer`, `FlightSearchRequest`), DTOs, mapper. | Import UIKit. Know about views. | MUST `[PDF p.4]` |
| **Service** (network) | `FlightSearchServicing` protocol, `HTTPClient`, endpoint, caching decorator. Returns `[FlightOffer]` or throws a typed error. | Import UIKit. Know about state or UI copy. | SHOULD |
| **ViewModel** | Screen **state** (`loading/success/empty/error`), **makes the API call** (via injected service), sorting, formatting into view data, reports events via **delegate or closure**. | **Import UIKit** (incl. navigation types). **Know the Coordinator exists.** Hold anything it can call navigation methods on. | MUST `[PDF p.4]` |
| **View** (`UIViewController` + cells) | Rendering state, forwarding user intents to the VM (`load()`, `retry()`, `selectSort(_:)`, `didTapLearnMore(promoID:)`, `didSelectOffer(at:)`). | Call the API, sort, format, open URLs, push/present anything, reference a Coordinator. | SHOULD |
| **Coordinator** | Building the screen (VM + VC + dependencies), owning the `UINavigationController`, **all navigation** (opening gozayaan.com). Implements the VM's delegate protocol. | Contain business logic or state. | MUST `[PDF p.2, p.4]` |

### 8.2 Architecture requirements

| ID | Requirement | Priority | Verify |
|---|---|---|---|
| ARCH-01 | ViewModel files `import Foundation` only (Combine allowed if used). **No `import UIKit`, no `UIViewController`, `UINavigationController`, `UIApplication`, `SFSafariViewController`.** | MUST | `grep -n "import UIKit" …/FlightResultsViewModel*.swift` → no hits. |
| ARCH-02 | ViewModel has **no reference** to any Coordinator type. It talks outward only through `weak var delegate: FlightResultsCoordinatorDelegate?` (protocol, `AnyObject`) and a state closure. | MUST | Code search for "Coordinator" in VM shows only the protocol type of `delegate`. |
| ARCH-03 | ViewModel is **unit-testable on its own**: no UIKit and no Coordinator in the test. | MUST `[PDF p.4]` | VM test file does not import UIKit and does not instantiate a coordinator. |
| ARCH-04 | All dependencies injected via `init` (service, providers, formatter, initial request). No singletons inside VM. | SHOULD | VM tests construct it with mocks only. |
| ARCH-05 | `SceneDelegate` creates and **strongly retains** an `AppCoordinator` and calls `start()`. `SceneDelegate` never instantiates view controllers directly. | MUST `[AUDIT A-10]` | App launches; coordinator not deallocated (Learn more still works after launch). |
| ARCH-06 | Delegate is `weak`; closures capture `[weak self]`; no retain cycles between VC ↔ VM ↔ Coordinator. | SHOULD | Memory graph debugger: no cycles. |
| ARCH-07 | Pure types (DTOs, `FlightOffer`, mapper, sorter, formatter) are `nonisolated` and `Sendable` so they can be tested and decoded off the main actor (project default isolation is `MainActor`). ViewModel is explicitly `@MainActor`. | SHOULD `[AUDIT A-12]` | Tests compile without `@MainActor` on mapper tests. |
| ARCH-08 | Flight tap is reported but performs no navigation (no detail screen in scope). | SHOULD | — |

### 8.3 Protocols (contract)

```swift
// Given by the brief [PDF p.4], extended with the one real navigation event.
protocol FlightResultsCoordinatorDelegate: AnyObject {
    func didSelectFlight(_ offer: FlightOffer)
    func didSelectPromo(_ promo: Promo)          // Coordinator opens promo.url (gozayaan.com)
}

protocol FlightSearchServicing: Sendable {
    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer]
}

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}
```

> Name `FlightResultsCoordinatorDelegate` is kept exactly as in the brief for traceability. The ViewModel only sees a protocol — it has no idea what concrete object implements it.

### 8.4 Event flow — Learn more (the only navigation)

```
Promo cell "Learn more" tap
  → FlightResultsViewController      (forwards intent, no logic)
  → viewModel.didTapLearnMore(promoID:)
  → delegate?.didSelectPromo(promo)  (VM knows only the protocol)
  → FlightResultsCoordinator         (implements protocol)
  → presents SFSafariViewController(url: https://gozayaan.com)   [DECISION D-13]
```

### 8.5 Proposed folder structure

```
GoZayanProject/
├── App/                     AppDelegate, SceneDelegate
├── Coordinators/            Coordinator, AppCoordinator, FlightResultsCoordinator
├── Features/FlightResults/
│   ├── ViewModel/           FlightResultsViewModel, FlightResultsState, FlightResultsError,
│   │                        FlightCardViewData, SortOption, FlightOfferSorter
│   ├── View/                FlightResultsViewController, RouteHeaderView, DateStripView,
│   │                        FlightCardCell, SkeletonCardCell, PromoCarouselCell, PromoCardCell,
│   │                        EmptyStateView, ErrorStateView, ShimmerView
│   └── DummyData/           PromoProvider, FareCalendarProvider
├── Models/                  FlightOffer, FlightSearchRequest, Promo, DateFare, LocalDateTime
├── Services/
│   ├── Network/             HTTPClient, Endpoint, RequestMethod, RequestError (fixed, §11)
│   ├── SerpApi/             SerpApiFlightsEndpoint, DTOs, FlightOfferMapper, FlightSearchService
│   └── Cache/               CachingFlightSearchService, FixtureFlightSearchService (DEBUG)
├── Shared/                  Formatters, APIKeyProvider
└── Resources/               Assets, FlightResultsFixture.json
GoZayanProjectTests/         Mapper, ViewModel, Sorter, Formatter, HTTPClient tests + fixtures
Config/                      Secrets.example.xcconfig (committed), Secrets.xcconfig (ignored)
spec/                        REQUIREMENTS.md (this file)
NOTES.md
```

---

## 9. UI implementation requirements

| ID | Requirement | Priority |
|---|---|---|
| UI-01 | **UIKit** (the project is already UIKit + XIB + `UINavigationController`). `[DECISION D-14]` | SHOULD |
| UI-02 | Main list: `UICollectionView` + compositional layout + diffable data source; carousel is an orthogonally-scrolling section or a nested horizontal collection. Updating sort must animate/update **in place** (no full reload flicker). | SHOULD `[PDF p.4]` |
| UI-03 | Skeleton, empty and error views occupy the content area below header + strip; header + strip stay put. | SHOULD |
| UI-04 | Supports Dynamic Type without clipping key info (price, times) — at least up to `xxxLarge`. | SHOULD |
| UI-05 | VoiceOver: each flight card is one accessibility element with a combined label, e.g. "Biman Bangladesh Airlines, departs 12:30 DAC, arrives 16:50 BKK, 4 hours 40 minutes, Non-Stop, BDT 37,400". Edit button marked decorative/disabled if it does nothing. | SHOULD |
| UI-06 | iPhone, portrait only (design is a portrait phone screen). Currently landscape + iPad enabled → change. | SHOULD `[DECISION D-15]` `[AUDIT A-13]` |
| UI-07 | Light appearance per Figma; if dark mode is not designed, force light (`overrideUserInterfaceStyle`) and say so in NOTES. | SHOULD `[DECISION D-16]` |
| UI-08 | No third-party dependencies (shimmer, image loading and layout done with UIKit). | SHOULD `[DECISION D-17]` |
| UI-09 | **All four states can be demonstrated on demand** in DEBUG via launch argument `-FlightsStubState loading|success|empty|error` (swaps in a stub service; `loading` never completes). *Interim (UI step): `-FlightsPreviewState` drives `FlightResultsPreview` sample data until the ViewModel exists.* Needed because a cached response loads instantly and reviewers must "see all of them". | SHOULD `[PDF p.2]` `[DECISION D-18]` |

---

## 10. Extra credit (optional) `[PDF p.4–6]`

### 10.1 Sorting

| ID | Requirement | Priority |
|---|---|---|
| EXT-01 | The **"Cheapest" dropdown** works (custom dropdown matching the Figma frame "Cheapest (Sorting Drop Down)"; `UIMenu` could not match it) with two options: **Cheapest** (lowest price) and **Fastest** (shortest total duration). Button title reflects the current option. | MAY |
| EXT-02 | List updates **in place**. | MAY |
| EXT-03 | Sorting lives **in the ViewModel as a plain function over offers** — e.g. `static func sort(_ offers: [FlightOffer], by: SortOption) -> [FlightOffer]` — not computed by the View while drawing. | MAY (MUST if sorting is done) `[PDF p.4]` |
| EXT-04 | Cheapest: `price` ascending; `nil` price last; tie → `durationMinutes` ascending; tie → original order (stable). | MAY |
| EXT-05 | Fastest: `durationMinutes` ascending; tie → `price` ascending (`nil` last); tie → original order (stable). | MAY |
| EXT-06 | Default sort = **Cheapest** (matches the design label). Sort selection persists across retry/reload. | MAY `[DECISION D-19]` |
| EXT-07 | Carousel position (FR-07) is applied **after** sorting. | MAY |
| EXT-08 | Sort control disabled in loading/empty/error. | MAY |

### 10.2 Unit tests — cover the parts that don't need UIKit `[PDF p.5]`

Network is **stubbed/mocked**; tests never call the live API.

| ID | Test | Priority |
|---|---|---|
| T-MAP-01 | Non-stop itinerary → `stops == 0`, label `Non-Stop`, codes/times/duration/price correct. | MAY |
| T-MAP-02 | 2-leg itinerary, 1 layover → `1 Stop`; arriveTime = **last** leg arrival. | MAY |
| T-MAP-03 | **3-leg multi-leg itinerary → `2 Stop`** (explicitly requested). | MAY `[PDF p.5]` |
| T-MAP-04 | `layovers` key absent on a 2-leg itinerary → stops from `flights.count − 1`. | MAY |
| T-MAP-05 | `best_flights` absent, `other_flights` present → offers from other only; order best→other preserved when both present. | MAY |
| T-MAP-06 | Both arrays absent / empty / 200-with-`error` → `[]` (drives empty). | MAY |
| T-MAP-07 | Itinerary with empty `flights` or unparseable time → dropped, others kept. | MAY |
| T-MAP-08 | Missing `price` → offer kept with `price == nil`. | MAY |
| T-MAP-09 | Time `"2026-02-15 12:30"` formats as `12:30` regardless of `TimeZone` (run under two different zones). | MAY |
| T-MAP-10 | Decoding the real captured fixture succeeds and yields > 0 offers. | MAY |
| T-VM-01 | Initial state `.loading`. | MAY |
| T-VM-02 | `loading → success`. | MAY `[PDF p.5]` |
| T-VM-03 | `loading → empty`. | MAY `[PDF p.5]` |
| T-VM-04 | `loading → error` (one test per error kind mapping). | MAY `[PDF p.5]` |
| T-VM-05 | Retry after error → `loading → success`. | MAY |
| T-VM-06 | Stale response from a cancelled load is ignored. | MAY |
| T-VM-07 | `didTapLearnMore` calls delegate `didSelectPromo` with the right URL; `didSelectOffer` calls `didSelectFlight`. Uses a spy delegate — no coordinator. | MAY |
| T-SORT-01..04 | Cheapest, Fastest, `nil` price last, stable ties. Sort change does not call the service. | MAY |
| T-FMT-01..03 | Price `BDT 37,400`; duration `4h 40m` / `2h` / `45m`; stops labels. | MAY |
| T-NET-01 | `HTTPClient` status mapping with a `URLProtocol` stub: 200 → decode, 401 → unauthorized, 429 → quotaExceeded, 500 → server, offline `URLError` → offline, bad JSON → invalidResponse. Verifies method/headers are actually applied to the request. | MAY |

Requires adding a **unit test target** (`GoZayanProjectTests`) — none exists today `[AUDIT A-14]`.

---

## 11. Existing codebase audit

Current state (branch `main`, 1 commit + uncommitted changes): Storyboard removed, programmatic window in `SceneDelegate`, empty `HomeViewController` (+ XIB), a generic `Network/` layer. **No Coordinator, ViewModel, models, tests, or feature UI yet.**

| ID | File | Finding | Why it matters | Required action |
|---|---|---|---|---|
| A-01 | `Network/HTTPClient.swift` | Builds a `URLRequest` (method, headers, body, cache policy) and then **ignores it** — calls `URLSession.shared.data(from: url)`. | Headers/method/body never sent. Classic AI-style bug reviewers look for. | Send the built `URLRequest` (`data(for: request)`). |
| A-02 | `Network/HTTPClient.swift` | Custom `URLSession.data(from:)` extension re-implements an API Apple already ships (iOS 15+) with the same name. | Shadowing/ambiguity; redundant continuation code. | Delete the extension; use Foundation's async API. |
| A-03 | `Network/HTTPClient.swift` | Manual `URLCache` read/write inside the generic client; key includes `api_key`; no TTL; would also cache "no results" bodies. | Mixed responsibilities, can serve stale data forever, not controllable in tests. | Move to `CachingFlightSearchService` decorator (CACHE-01..04). |
| A-04 | `Network/HTTPClient.swift` | `try? JSONDecoder().decode` and `catch { return .failure(.unknown) }`. | Swallows `DecodingError` and `URLError` — can't tell offline from bad data. | Propagate typed errors (§4.3, DATA-12). |
| A-05 | `Network/HTTPClient.swift` | Only 2xx / 401 handled. | 429 (quota) is realistic with a 100-search trial. | Map 401/403/429/5xx/other (§4.3). |
| A-06 | `Network/HTTPClient.swift` | `URLSession.shared` hard-coded; `JSONDecoder` created inline. | Can't inject a stubbed session for T-NET-01. | Inject `URLSession` and decoder. |
| A-07 | `Network/RequestError.swift` | `import UIKit` in a network error type; UI copy (`errorMessage`) lives in network layer; typo "Unknow  error". | Leaks UIKit into non-UI layers; mixes concerns. | `import Foundation`; move user messages to presentation (ERR-02). |
| A-08 | `Network/Endpoint.swift` | `body: [String: String]?` only supports string values; unused for GET. | Minor. | Keep simple or remove for GET-only use. |
| A-09 | `Network/*.swift` | File headers say `BS24TestProject` / another author, dated 2024. | Reviewers read the code and history; unexplained reused code hurts "code review judgment". | Rewrite or clearly disclose reuse in `NOTES.md`; fix headers. |
| A-10 | `SceneDelegate.swift` | Instantiates `HomeViewController` directly; no Coordinator. | Violates ARCH-05. | Create/retain `AppCoordinator`. |
| A-11 | `ViewController.swift`, `HomeScreen/*` | Leftover template `ViewController`; "Home" naming for a Flight Results screen; empty XIB. | Dead code / misleading names. | ✅ Done in UI step: deleted, replaced by programmatic `FlightResultsViewController`. |
| A-12 | Build settings | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, Swift 5 mode. | Every type (DTOs, mapper) is implicitly `@MainActor` → friction in tests/decoding. | Mark pure types `nonisolated` (ARCH-07). |
| A-13 | Build settings | `IPHONEOS_DEPLOYMENT_TARGET = 26.2`; iPhone landscape + iPad enabled. | Reviewers on older Xcode/simulators may not run it; design is portrait phone. | Lower target (D-15); iPhone portrait only. |
| A-14 | Project | No unit-test target. | Needed for extra credit. | Add `GoZayanProjectTests`. |
| A-15 | Git | Changes uncommitted; only "Initial Commit". | History is scored; spec must visibly come first. | Commit current cleanup, then this spec, **before** prompting feature code. |

---

## 12. Decisions on open points `[PDF p.6]`

> "Ask us, or decide for yourself and tell us why. A choice you can explain always beats a silent guess." — every row below must appear in `NOTES.md`.
> **Items marked ❓ need confirmation from you before implementation starts.**

| ID | Open point | Proposed decision | Why |
|---|---|---|---|
| D-01 ❓ | Route & date | **DAC → BKK**, **1 adult**, **BDT**, `outbound_date = today + 30 days` (computed at launch). | Matches the brief's example route/currency. The example date (2026-02-15) is already in the past; a relative date keeps the app working whenever reviewers run it. Trade-off: local cache/fixture keys change daily → covered by fixture fallback. |
| D-02 ❓ | Where the API key lives | Git-ignored `Secrets.xcconfig` → Info.plist → `APIKeyProvider`; DEBUG falls back to bundled fixture if key missing. | Key never in git; reviewers can run without their own key. |
| D-03 | Price format | `BDT 37,400` — ISO code, space, grouped integer, no decimals. | Exactly matches the brief's sample chip `BDT 70,129`; `NumberFormatter` currency style would give `৳` or locale-dependent output. |
| D-04 | Merging `best_flights` + `other_flights` | Concatenate best then other, preserving API order; no dedupe; keep `source` on the model. Then apply sort (default Cheapest). | Google already separates them without overlap; keeping `source` allows a "Best" badge later without re-mapping. |
| D-05 ❓ | What empty looks like | Not in Figma → our design: icon, "No flights found", "Try a different date or route.", "Search again" button. Header + strip remain. | Consistent with error layout; gives user a way forward. |
| D-06 | Carousel position | After the 2nd flight card; after last if < 2. | "Between the flight cards" — visible without scrolling, doesn't push the first results off screen. |
| D-07 | Missing price | Keep offer; show "Price unavailable"; sort last. | Dropping real flights silently is worse than showing them. |
| D-08 | Header in non-success states | Always visible (built from request). | User always knows what was searched, even on error. |
| D-09 ✅ | Multi-airline itineraries | Distinct names joined with " + ", tail-truncated. | Resolved by Figma. |
| D-10 | Date strip data | Hard-coded fares; dates generated around search date; selected = search date. | Satisfies "hard-coded dummy data" while keeping header and selected chip consistent. |
| D-11 | Flight card tap | Reported to delegate (`didSelectFlight`), Coordinator does nothing. | Brief defines the delegate but no detail screen. |
| D-12 | Promo images | Bundled assets. | Dummy data; no network or image-loading library needed. |
| D-13 ❓ | How gozayaan.com opens | `SFSafariViewController` presented by the Coordinator. | Keeps user in-app; clearly "navigation through the Coordinator". Alternative: `UIApplication.shared.open` (leaves app). |
| D-14 ✅ | UI framework / layout | UIKit, programmatic layout (empty XIB removed). | Project already UIKit + programmatic window; programmatic cells diff cleanly in reviews. |
| D-15 ❓ | Deployment target / devices | iOS **16.0**, iPhone only, portrait. | async/await, `UIContentConfiguration`, compositional layout all available; runs on older simulators. |
| D-16 | Dark mode | Force light unless Figma has dark variants. | Avoid unreviewed dark colours. |
| D-17 | Third-party libraries | None. | Small scope; less for reviewers to audit. |
| D-18 | Demonstrating all four states | DEBUG launch argument `-FlightsStubState`. | Reviewers "want to see all of them"; real API rarely yields empty/error on demand. |
| D-19 | Default sort | Cheapest. | Matches dropdown label in design. |

---

## 13. Figma — captured design (2026-09-15)

The Figma file is viewable without an account (inspect/dev mode is not), so layout and sizes were read from the canvas at 100–200% zoom and **colours were matched by eye**. All tokens live in `Shared/DesignSystem/Theme.swift`, so exact hex values can be swapped in one place.

Frames: **"Flight Result - After Search, One Way"** (loading), **"Flight Result - After Search, One Way"** (results), **"Cheapest (Sorting Drop Down)"**.

| Element | Design |
|---|---|
| Screen | Deep navy background (~`#0A0B80`), white status bar content. |
| Font | Geometric sans (not bundled). **SF Pro at the same sizes/weights is used as the stand-in.** |
| Route header | Back chevron (left), title **city names** "Dhaka - New York" 20 bold white, subtitle "15 Feb, 2025 \| 👤02 \| One Way" 13 regular. **No Edit button in Figma** — added at trailing edge because the PDF requires it (FR-01). |
| Date strip | Chips ~104 pt wide: day 13 regular, fare 15 semibold, white. Selected = yellow (~`#F7C948`) text + 3 pt yellow underline. Fixed 40×40 price-trend badge at trailing edge (yellow border/icon in results, white while loading). 1 pt translucent divider below. Loading: fares replaced by shimmering bars. |
| Sort / Filter row | "Cheapest ⌄" outlined white button (radius 6, 32 pt tall). "Filter" yellow filled button with sliders icon (decorative, out of scope). |
| Sort dropdown | White card, radius 8, soft shadow, rows "Cheapest"/"Fastest" 14 semibold; selected row light lavender background. Chevron flips up while open. |
| Loading | Orange (~`#F26B3A`) progress bar on white track (6 pt), "Hang tight! We're finding the best flight options for you." 20 semibold centred, skeleton cards (royal blue, radius 14, circle + 2 bars + pill, 112 pt tall), **promo carousel shown between skeletons too**. |
| Flight card | White, radius 8, 16 pt padding, 12 pt gap. Row 1: 20 pt logo + airline 15 regular (truncates tail), "Get Points" + coin icon (decorative). Row 2: times 20 bold, codes 14 grey; centre column duration 12 / route line / stops 13. Route line: open circles at ends, **one filled dot per stop**. Arrival "+1Day"/"+2Day" red superscript. Dashed divider. "Starting from" 13 grey + "BDT" 14 grey + amount 20 bold navy, right aligned. |
| Multi-airline | "Air Arabia + US Bangla Airlin…" — names joined with " + ", tail truncated; generic airline icon. |
| Promo card | ~48–52 pt tall banner: navy image block left, mint (~`#E9FBF0`) body, title 13 semibold 2 lines, "Learn more ↗" 11 underlined; carousel scrolls sideways, cards peek on both sides. |
| Placement | Carousel after the **2nd** flight card (and after the 2nd skeleton while loading). |
| Not in Figma | Empty and error states → our design (D-05) using the same tokens. "Flight Details" link appears only in the dropdown frame, not the reference results frame → not built. |

---

## 14. Non-functional requirements

| ID | Requirement | Priority |
|---|---|---|
| NFR-01 | App builds with zero warnings in the committed configuration and launches without crashing on any response (including malformed). | SHOULD |
| NFR-02 | No force unwraps on API data. | MUST |
| NFR-03 | Scrolling the result list stays smooth (cells reused, formatters cached, no work in `cellForItem` beyond binding). | SHOULD |
| NFR-04 | No secrets in logs, UI, fixtures or git history. | MUST |
| NFR-05 | Network timeout 30 s; no automatic retry loops (manual retry only, protects quota). | SHOULD |

---

## 15. Process requirements (scored) `[PDF p.1, p.5]`

| ID | Requirement | Scored area |
|---|---|---|
| PROC-01 | Commit this spec **before** any AI-generated feature code. | Spec quality (full weight for Option A) |
| PROC-02 | Drive the AI **step by step**, one slice per prompt, each prompt referencing spec IDs (e.g. "Implement MAP-01..MAP-11 in `FlightOfferMapper` + tests T-MAP-01..10"). Never one giant "build this app" prompt. | AI direction |
| PROC-03 | Review every AI output against the spec; log what was wrong and why in `NOTES.md` as it happens (not reconstructed at the end). | Code review judgment |
| PROC-04 | Record which architecture decisions were ours vs the AI's. | NOTES / Communication |
| PROC-05 | Be ready to explain every row of §12 on the call. | Communication |

### Suggested build order (one prompt/commit per step)

1. Project cleanup: remove template leftovers, fix build settings (A-11, A-12, A-13), add test target (A-14), Secrets xcconfig (KEY-01..03).
2. Models + DTOs + `FlightOfferMapper` + fixtures + mapper tests (§6, T-MAP-*).
3. Network fix-up: `HTTPClient` (A-01..A-07), SerpApi endpoint, `FlightSearchService`, error mapping, T-NET-01.
4. Caching decorator + fixture/stub services (CACHE-*, UI-09).
5. `FlightResultsViewModel` + state + sorter + formatter + tests (§4, §10, T-VM-*, T-SORT-*, T-FMT-*).
6. Coordinators + SceneDelegate wiring (§8, ARCH-05).
7. UI: header, date strip, skeleton/shimmer (FR-01..03).
8. UI: flight cards, carousel, Learn more through coordinator (FR-04..07).
9. UI: empty + error states, sort menu (ST-03, ST-04, EXT-01).
10. Figma polish pass, accessibility, `NOTES.md` final pass, README run instructions.

---

## 16. Definition of Done

The task is done when **all** of the following are true:

- [ ] **DoD-01** Fresh clone + key setup (or no key → fixture) builds and runs on an iPhone simulator.
- [ ] **DoD-02** Route header shows origin → destination, date, passenger count, "One Way", Edit button (FR-01).
- [ ] **DoD-03** Date strip scrolls horizontally, shows hard-coded fares, selected day highlighted, taps ignored (FR-02).
- [ ] **DoD-04** Loading state shows shimmer skeleton cards (FR-03, ST-01).
- [ ] **DoD-05** Success state shows flight cards with airline, depart/arrive time, duration, stops label, both airport codes, starting price (FR-04, ST-02).
- [ ] **DoD-06** Discount carousel scrolls sideways between flight cards with image, title, Learn more (FR-05).
- [ ] **DoD-07** Learn more opens gozayaan.com via the Coordinator only (FR-06).
- [ ] **DoD-08** Empty state reachable (real 0-result response or stub) and shown correctly (ST-03).
- [ ] **DoD-09** Error state reachable (offline / bad key / stub) with retry (ST-04).
- [ ] **DoD-10** Live SerpApi one-way request works; `best_flights` + `other_flights` merged into one list of `FlightOffer` (DATA-*, MAP-01).
- [ ] **DoD-11** Multi-leg itinerary shows **2 Stop** (MAP-02, MAP-03).
- [ ] **DoD-12** ViewModel imports no UIKit and has no Coordinator reference; reports events via delegate/closure (ARCH-01..03).
- [ ] **DoD-13** Navigation code exists only in Coordinators (ARCH, FR-06).
- [ ] **DoD-14** Responses cached locally in development; tests never hit the network (CACHE-*).
- [ ] **DoD-15** No API key in the repo or its history (KEY-01, DEL-08).
- [ ] **DoD-16** UI matches the two Figma frames (FR-08).
- [ ] **DoD-17** `/spec` folder, `NOTES.md` (AI tool, corrections/throw-aways, own architectural decisions, decisions from §12) present at repo root (DEL-02, DEL-04).
- [ ] **DoD-18** Commit history is incremental and shows spec first (DEL-05, PROC-01).
- [ ] **DoD-19** Repo pushed and link sent within 3 days of receiving the task (DEL-01, DEL-06).
- [ ] *(Optional)* **DoD-20** Cheapest/Fastest sort in ViewModel, list updates in place (EXT-*).
- [ ] *(Optional)* **DoD-21** Unit tests for mapping (incl. 2 Stop), state transitions, sort — all green with stubbed network (T-*).

---

## 17. Changes made during implementation (v3 · 2026-09-15)

Each change below was forced by something verified while building (live API call, compiler, simulator, or tests). The rows above keep their original wording so the history of the spec stays readable; this table wins where they differ.

| Spec IDs | Change | Why |
|---|---|---|
| DATA-03, D-01, D-03 | Search currency is **USD**; prices read `USD 297`. | SerpApi rejects BDT: `HTTP 400 {"error": "Unsupported `BDT` for currency."}` — the brief's own example request fails. Currency is one value in `FlightSearchRequest.defaultSearch`. |
| KEY-02, D-02 ✅ | Key lives in git-ignored `GoZayanProject/Config/Secrets.plist`, read by `APIKeyProvider`. Template: `Secrets.example.plist` at the repo root. No key in Debug → bundled fixture. | No project-file build settings to maintain, and a fresh clone without the file still builds (a missing xcconfig include would not). |
| CACHE-01…04 | Cache is `CachingHTTPClient`, a decorator around `HTTPClient` that stores raw 2xx bodies in `Caches/HTTPResponseCache` for 24 h; file name = SHA-256 of the request **without** `api_key`. Debug only; `-FlightsBypassCache YES` skips it. | Raw bodies must be cached below the mapping step, so the decorator sits at the HTTP layer instead of wrapping the service. The service stays unaware of caching. |
| §5.1 | `FlightSearchRequest.outboundDate` is a `CalendarDay`, not a `Date`; the request also carries city names for the header. | A calendar day has no time zone to get wrong. |
| MAP-06, MAP-09 | An itinerary with neither `total_duration` nor leg durations is dropped. | A card can't show a duration it doesn't have. |
| MAP-11 | Airport times are stored as `LocalDateTime` components (no `Date`). | The device time zone can't shift what is shown. |
| §8.3 | `FlightResultsCoordinatorDelegate` gained `didSelectPromo(_:)`. | Learn more is the one real navigation event. |
| UI-09 | `-FlightsStubState loading\|success\|empty\|error` swaps in `StubFlightSearchService`; the arguments are pre-listed (disabled) in the shared scheme. The UI-step preview harness was deleted. | Reviewers can see every state without editing code. |
| D-13 ✅ | `FlightResultsCoordinator` presents `SFSafariViewController` for gozayaan.com. | In-app, and navigation stays in the Coordinator. |
| A-01…A-07 ✅ | Network layer rewritten: `URLSessionHTTPClient` sends the built request, injects its session, maps 401/403/429/5xx and offline errors to `RequestError`, and never swallows decoding errors. `RequestError` no longer imports UIKit or holds UI copy. | See §11. |
| A-10 ✅, ARCH-05 | `SceneDelegate` retains `AppCoordinator`; `AppDependencies` is the composition root. | |
| §10.2, A-14 | **Unit tests dropped** (extra credit, optional). A test suite was written and passing, then removed at the candidate's request. No test target in the project. | The candidate chose not to submit tests they would not be able to explain on the walkthrough call. The ViewModel stays testable (Foundation only, dependencies injected). |

Facts confirmed from the live response (`Resources/FlightResultsFixture.json`, scrubbed): non-stop itineraries **omit** `layovers`; an itinerary can **omit** `price`; overnight arrivals are common; the body never contains the API key.

Still open: **D-15** — deployment target is still iOS 26.2.

