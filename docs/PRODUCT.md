# Product Notes

## Positioning

DoseLab is a medication self-observation tool for users who are comfortable with parameters, models, logs, and personal data ownership.

It is not designed as a mass-market patient app. It should feel more like a personal medication lab, dosing rhythm dashboard, and open PK visualization tool.

## Target Users

- People with long-term medication needs
- Users interested in pharmacokinetics and dosing rhythm
- Quantified-self and open-source health tool enthusiasts
- Users who want transparent local records for doctor/pharmacist conversations

## MVP Scope

- Medication entries
- Dose strength management
- Dose schedules
- Dose logs
- Half-life based concentration curve
- Therapeutic window visualization
- Peak/trough markers
- Custom thresholds
- FDA medication reference data retrieval
- Data source metadata, including source URL, retrieval time, and update status
- JSON import/export
- Material 3 light/dark theme
- Responsive layout

## Non-Goals For MVP

- Medical advice
- Automatic dose adjustment
- Diagnosis or treatment recommendation
- Mandatory cloud accounts
- Full clinical interaction database

## FDA Data Source Requirements

- FDA-sourced medication data must be presented as reference data, not medical advice.
- Imported or fetched data must retain source metadata, including source URL, retrieval time, and update status.
- Initial integration should use openFDA `drug/ndc` for medication lookup and openFDA `drug/label` for SPL label sections; see `docs/FDA_API.md`.
- Users must be able to review and override locally stored medication parameters when appropriate.
- The app should degrade gracefully when FDA data is unavailable, stale, incomplete, or does not match a user-entered medication.
