## 10.1.1

* Allow an artefact to be associated with multiple needs

## 10.0.0

* Add validation for tag IDs

## 9.0.1

* Bugfix: `whole_body` can return nil for CompletedTransactionEdition because the body field is no longer used.

## 9.0.0

* Removes `business_support_identifier` field from BusinessSupportEdition.

## 8.10.0

* Adds a flag to `attaches` to have the `Attachable`
mixin add a {field}_url attribute containing the
attachment's public URL.

## 8.9.0

* Add label fields to RenderedSpecialistDocument

## 8.8.0

* Add two new formats from Whitehall; Notice and Decision.

## 8.6.0

* add `RenderedSpecialistDocument#create_or_update_by_slug!` and `RenderedSpecialistDocument#find_by_slug`

## 8.4.1

* Bugfix: Prevent rails dev-mode reloading from clearing configuration of
  Attachable api client.

## 8.4.0

Add support for attachments to SpecialistDocumentEdition.

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
