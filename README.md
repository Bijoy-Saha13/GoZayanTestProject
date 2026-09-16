# Flight Results — GoZayaan iOS take-home

One screen, Flight Results, in all four states (loading, success, empty, error). UIKit, MVVM + Coordinator, real data from the SerpApi Google Flights API.

## Requirements

- Xcode 26 (built with 26.3)
- iPhone simulator on iOS 17.0 or later

## Run it

Open `GoZayanProject.xcodeproj`, pick an iPhone simulator, and run.

**No API key needed.** Without one, Debug builds show a bundled real SerpApi response (DAC → BKK).

**To use live data**, copy the template and add your SerpApi key. The copy is git-ignored, so the key is never committed.

```bash
mkdir -p GoZayanProject/Config && cp Secrets.example.plist GoZayanProject/Config/Secrets.plist
```

Then replace `YOUR_SERPAPI_KEY` in the copy with your key. Live responses are cached for 24 hours in Debug builds to save searches.

## See each state

In Xcode: **Product → Scheme → Edit Scheme → Run → Arguments**. The arguments are already listed, unticked. Tick one and run.

| Argument | Shows |
|---|---|
| `-FlightsStubState loading` | Loading skeletons (never finishes) |
| `-FlightsStubState success` | Results, including one sample 2-stop flight |
| `-FlightsStubState empty` | No flights found |
| `-FlightsStubState error` | No internet connection, with Try again |
| `-FlightsBypassCache YES` | Skips the 24-hour cache and makes a live request |

## Where to look

- `spec/REQUIREMENTS.md` — the spec, committed before the feature code
- `NOTES.md` — AI tool, what was corrected or thrown away, architecture decisions
- `GoZayanProject/` — the app: `Features/FlightResults` (View, ViewModel), `Coordinators`, `Models`, `Services`
