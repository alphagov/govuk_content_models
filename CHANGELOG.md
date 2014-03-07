## 8.3.1

Added `Edition#locked_for_edits?`

## 8.3.0

Add `editors_note` field to the edition model

## 8.2.0
* Added support for publishing editions in the future
* Removed #capitalized_state_name, in favor of #status_text which shows a publish_at time for editions scheduled for publishing

## 8.1.0

This adds a new tag type for an artefact called "organisations".

## 8.0.0
* Remove `lined_up` state and `start_work` transition
* `draft` is the new default state
* Editions can now be transitioned from Out for fact check and Ready to Amends needed
* Fact check received can transition back to Out for fact check

## 7.2.1

Added Finder artefact kind

## 7.2.0

## 6.4.0

Added SpecialistDocumentEdition

## 6.1.0

makes this gem compatible with gds-sso (9.2.0)
by adding the organisation_slug to User.
