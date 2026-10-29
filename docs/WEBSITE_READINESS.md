# Website readiness before income setup

Owner direction, 2026-10-28: complete the Movie Tracker website first, then
return to income/business setup. Work remains zero-spend, with monetization off.

## Current evidence

- Production `main`: `d5eda948feb39616f6829c09100ce94c52f50273` at the start of this pass.
- A fresh desktop browser session loaded the app and movie catalog.
- Source inspection found a search race: older responses/errors could replace
  newer results, stop a current spinner, or reappear after clearing/category
  changes. This branch guards request identity and adds retry controls.
- This branch adds a web loading screen, slow-start/reload recovery, supported
  Flutter initialization hooks, and positioning above mobile bottom navigation
  for the existing project link. It does not read/write saved user data.
- Search regression tests and JavaScript startup tests are part of this branch.
  Release requires a passing Flutter CI run; source presence is not a test pass.

## Remaining acceptance work

- [ ] Verify this branch's CI, release web build, and startup behavior.
- [ ] Verify mobile layout, keyboard navigation, search clearing/retry, and
  movie/TV detail navigation against the release build.
- [ ] Review the Google search links in PR #40: complete the generated lockfile
  review without unrelated Firebase/cloud-sync dependency churn and verify web
  popup behavior plus relevant native platforms before merging that feature.
- [ ] Complete PR #39's separate diary data-safety acceptance: original and
  duplicate rewatches, profile switch with picker open, reload, and sync in
  both directions on two devices. Never bypass that PR's merge requirements.
- [ ] Verify sign-in, profile switching, offline edits, reload, and reconnect
  using designated test profiles/accounts; preserve production history.
- [ ] Recheck deployed release health after an approved merge/deployment.

## Deferred business work

No payments, ads, affiliate links, subscriptions, new customer commitments,
work-authorization setup, or commercial hosting changes are activated here.
Actual provider availability remains subject to issue #32. PR #40 provides
user-initiated Google search links, not an in-app availability feed or a
licensing clearance. Technical completion does not waive these requirements.
