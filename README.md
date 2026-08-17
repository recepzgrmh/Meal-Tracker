# Meal Clarity

An accuracy-first mobile meal logger built for the EatBetter full-stack case
study.

The first vertical slice is intentionally local and deterministic:

- Today dashboard with totals derived from meal items
- Natural-language meal composer
- Mock analysis behind a replaceable `MealRepository` boundary
- Editable structured food review
- Human-in-the-loop portion clarification
- Log success with undo instead of a blocking success screen
- Catalog photography with explicit provenance labels
- Meal detail with deterministic portion editing and delete confirmation

![Current iOS progress](meal-clarity-progress.png)

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```

The product and architecture research is in
`CASE_STUDY_RESEARCH_REPORT_TR.md`.

Generated food asset disclosure is in `docs/ASSET_PROVENANCE.md`.
