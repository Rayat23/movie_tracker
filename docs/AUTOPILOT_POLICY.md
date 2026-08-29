# Movie Tracker Autopilot Policy

This document records the standing operating rules approved by the project owner for ongoing autonomous maintenance and development.

## Default operating mode

- Prefer free/no-cost, reversible, low-risk choices.
- Batch small safe improvements together.
- Work on one major roadmap item at a time.
- Routine low-risk fixes may be committed and pushed automatically to non-production branches.
- Low-risk PRs may merge automatically only after all required CI/tests pass.
- Major features must use their own branch/PR and require owner approval before merge.
- The first production launch requires explicit owner approval. After that, CI-green `main` updates may auto-deploy.

## Reliability and data

- Do not depend on the owner's local computer or home internet for ongoing operations.
- Tracking changes should save locally immediately, queue offline, retry later, and sync when connectivity returns.
- Preserve both sides of sync conflicts when possible and ask only when a safe automatic resolution is not possible.
- Never silently delete cloud/user data.
- Investigate CI, deployment, and site-health failures automatically and apply safe reversible fixes first.
- Notify the owner only for approvals, unrecoverable problems, security/data risks, or major milestones.

## Privacy, security, and accounts

- Accounts, profiles, lists, and tracking data are private by default.
- Public sharing must be explicitly enabled by the user.
- Email verification is required before sensitive/public-account features, while basic local usage may remain available.
- Never weaken authentication, Firestore rules, or privacy protections without owner approval.

## Cost and monetization

- Zero-spend mode is the default.
- Never enable billing, paid infrastructure, charges, or purchases without owner approval.
- Monetization infrastructure may be prepared, but Movie Tracker ads/subscriptions must not be activated until API/licensing requirements are cleared.
- Keep the Movie Tracker brand for now; avoid paid domain/brand changes until there is traction.

## Remote-service business funnel

- A separate website/app/AI-automation service funnel may be prepared using Movie Tracker as proof of work.
- Lead qualification, intake, scoping questions, and non-binding draft replies may be automated.
- Routine acknowledgement/detail-request replies may be automated once templates are established.
- Binding quotes, deadlines, jobs, contracts, charges, or payments require owner approval.
- Paid commitments remain disabled until the owner confirms applicable work-authorization/business requirements.
- Use a separate business contact email publicly rather than exposing the owner's personal email.

## Escalation rule

When an unlisted choice appears, choose the safest free/no-spend/reversible option. Ask the owner only when the decision involves money, data loss, security/privacy, production risk, legal terms, or a business commitment.
