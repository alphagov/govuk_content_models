# CHANGELOG

## 29.0.1

- Bugfix: updated_at field on non-archive editions was being updated whenever an Artefact was saved. Now only do so when the slug has changed.

## 29.0.0

- Remove fields from Artefact:
  - `department`
  - `business_proposition`
  - `fact_checkers`
- Remove fields from Edition:
  - `business_proposition`
  - `department`

## 28.10.0

- Add conversion from LicenceEdition to AnswerEdition in `Edition#build_clone`

## 28.9.0

- Add `department_analytics_profile` to transaction editions

## 28.8.0

- Add `redirect_url` to artefact

## 28.7.1

- Change the scheduled publishing timestamp to be London local time
  instead of UTC.
## 28.7.0

- Add `vehicle_recalls_and_faults_alert` artefact format

## 28.6.2

- Relax constraint on govspeak dependency from `~> 3.1.0` to `~> 3.1`.

## 28.6.1

- Copy the body from the old edition to the new edition when converting from
  Answers, Guides, Programmes and Transactions to Simple Smart Answers

## 28.6.0

- Add `presentation_toggles` field to CompletedTransactionEdition

## 28.5.0

- Add `countryside_stewardship_grant` artefact format

## 28.4.0

- Add `european_structural_investment_fund` artefact format

## 28.3.0

- Add error message when validating primary and additional topics
- Embed part errors within edition errors

## 28.2.0

- Add an index for `created_at` on Edition.

## 28.1.0

- Add a `Downtime` model to represent downtime for an artefact.

## 28.0.1

- Skip LinkValidator for archived editions.

## 28.0.0

- Removes `uses_government_gateway` and `minutes_to_complete` fields from
  `Edition` class

## 27.2.0

- Adds `unassign` instance method for `User` class which allows users to
  unassign an `Edition`.

## 27.1.0

Updates the LinkValidator to validate smart quotes in the same way as normal quotes

## 27.0.0

- Corrected to return public timestamp of first edition when no major changes
- Adds a unique index on the `uid` field for a `User`. (breaking change)

## 26.3.0 (yanked)
- Corrected to return public timestamp of first edition when no major changes
- Yanked due to the unintended inclusion of a breaking change.

## 26.2.0
- Adds `reviewer` `String` field to `Edition` class.

## 26.1.0
- Adds `review_requested_at` `DateTime` field to `Edition` class.

## 26.0.0

- Removes `Expectation` model and introduces `need_to_know` `String` field on
  Transaction, LocalTransaction and Place editions to store the expectations
  as a govspeak field.

## 25.0.0

- Removes the `alternative_title` field from the `Edition` class.
- Adds methods to return major updates for an `Edition`.

## 24.2.0

- Adds the `public_timestamp` and `latest_change_note` fields to the `Artefact`
  model.

## 24.1.0

* Use version numbers for picking current edition in 'Edition.find_and_identify'
* Changed to depend on the latest major release of gds-sso [10.0.0]
  which requires a `disabled` field to be defined on the `User` model.
  This field mirrors the user state in Signon.

## 24.0.1

* Corrected the request_type recorded in actions for a create_edition
action to 'create', a deviation introduced by changes in 24.0.0.

## 24.0.0

* Major clean-up which replaced `WorkflowActor` with `ActionProcessors`.
This is a breaking change, shouldn't break any existing functionality,
but may break re-opened classes, and tests relying on workflow helper
methods which were present in `WorkflowActor`.
* Added Edition fields `major_change` and `change_note`
* Improved the audit log for scheduled publishing to show scheduled time,
which requires storing it in the `action`.

## 23.0.0

* Remove important_notes field from Edition
* Add IMPORTANT_NOTE and IMPORTANT_NOTE_RESOLVED request_types to Action
* Add methods to find, create and resolve important note actions to Workflow and WorkflowActor.

## 22.2.0

* Allow new formats for raib_report for Artefacts
* Validate only govspeak fields for safe html

## 22.1.2

* Allow new formats for maib_report and for an Artefact

## 22.1.1

* Copy collection associations when cloning Editions

## 22.1.0

* Add default values for collection associations on Edition

## 22.0.0

* Remove old unused `tags` field from Edition
* Add browse and topic collection associations to Edition

## 21.0.0

* Remove diff-ing code from content models - diffs should now be calculated on the fly

## 20.2.0

* Adds new `finder_email_signup` Artefact kind and validator for finder e-mail signups.

## 20.1.0

* Adds new Whitehall publication sub-type format of `regulation` for Artefact

## 20.0.0

* Breaking change: Remove `section` field on `Edition`. This reduces coupling between Panopticon and Publisher apps. Section should be inferred from the edition's artefact instead.

## 19.0.0

* BREAKING CHANGE: String fields can no longer include arbitrary images. They
  must either be on a relative path, hosted on either www.gov.uk, assets.digital.cabinet-office.gov.uk or the equivalent domain for the local environment.

## 18.0.0

* BREAKING CHANGE: Remove specialist-document Artefact kind.
* Add new format for medical_safety_alert for an Artefact.

## 17.2.1

* Add new format for drug_safety_update for an Artefact

## 17.1.1

* Make `Artefact#as_json` handle missing tags gracefully

## 17.1.0
* Added `in_beta` field to `Edition`

## 17.0.0
* BREAKING CHANGE: Upgrade govspeak gem dependency.
  * This modifies how the SafeHtml validator will behave. It now permits tags
    it didn't before.

## 16.2.0
* Add published_at field to RenderedSpecialistDocument

## 16.1.1

* Make Tag#parent return the tag's parent even if it is draft.

## 16.1.0

* Add new format for international_development_fund for an Artefact

## 16.0.0

* Adds a workflow for Tags.
* BREAKING CHANGE: Tags are no longer live by default. Tests which create tags
  should migrate to use the new `:live_tag` factory when creating stub data.

## 15.1.2
* Use string-based keys rather than symbols when manipulating
  tuple hashes for tags on an artefact.

## 15.1.1
* Allow archiving of siblings with validation errors

## 15.1.0
* Add draft tag functionality to `Tag.by_tag_id/s`.
* Permit tag type to be provided via an options
  hash, while retaining backwards compatibility.

## 15.0.0
* Refactor tags.
* Provide draft functionality in the `taggable` trait.

## 14.1.1
* Use another way to transition Editions without
  validation

## 14.1.0
* Edition errors should not block receiving of
  fact check response, and related state transition.

## 14.0.1
* Valdations for Business support scheme dates.

## 14.0.0
* Remove `Attachment` model.

## 13.4.0

* Allow new formats for aaib_report and cma_case for an Artefact

## 13.3.0

* Adds a `state` field to `Tag`.

## 13.2.1

* Assigning an edition doesn't require the entire edition
  to be validated and saved. Hence replacing it with a
  set operation.

## 13.2.0

* Denormalising users doesn't require the entire edition
  to be validated and saved. Hence replacing it with a
  set operation.

## 13.1.0

* Perform link validation everytime an edition is saved,
  irrespective of which fields changed.

## 13.0.0

* Bundle metadata fields for `RenderedSpecialistDocument` into a single
  `details` hash.

## 12.4.0

* Allow new drafts to be created from published
  editions having link validation errors.

## 12.3.0

* Show all relevant errors in LinkValidator.

## 12.2.0

* Add ManualChangeHistory model and artefact kind.

## 12.1.0

* Add LinkValidator, which checks that links in Govspeak fields are properly
  formed and do not contain title text or rel=external. Remove
  GovspeakSmartQuotesFixer which is irrelevant now title text is no longer
  allowed.

## 12.0.0

* Remove `SpecialistDocumentEdition` model. It is only used by the
  specialist-publisher and is a concern of that application and how it handles
  versioning documents.

## 11.4.0

* Add `RenderedManual` model.

## 11.3.0

* When an artefact is saved, no longer attempt to update attributes on the
  edition model - with the exception of the slug field, which will only be
  updated when the artefact is in draft state.

## 11.2.0

* Added manual and manual-section formats with custom slug validation.

## 11.1.0

* Add area field to business support editions.

## 11.0.1

*  Destroying an edition lets siblings know.

## 11.0.0

*  Remove fact check logic from the `Edition` model, since it only belongs in
   Publisher.

## 10.5.0

*  Add Corporate information pages to Whitehall formats.

## 10.4.2

*  Making Artefact.relatable_items a scope so that it can be chained.

## 10.4.1

*  Fix tag validation; tags slugs may only contain `/` if they're a child tag.

## 10.4.0

* Add support for updating existing attachments

## 10.3.0

*  Add artefacts for specialist sector tags

## 10.2.2

-  Prevent a Mongo error when tag_ids are set to nil

## 10.2.0

* Adding a nil check around `need_ids` field in validations and using the correct gem version number to reflect the new feature that got added in 10.1.1.

## 10.1.2

* Use `\A\z` anchors instead of `^$` in need ID validation regex

## 10.1.1

* Allow an artefact to be associated with multiple needs

## 10.1.0

* Add `previous_edition_differences` method to simplify working with change histories.

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
