# Movie Tracker Autopilot Roadmap

## Operating mode

Movie Tracker is being developed in **zero-spend mode** until the owner explicitly approves otherwise.

The automation should keep routine work moving without depending on the owner's local computer being online. GitHub Actions and hosted services are the execution layer. The owner's device is only needed for approvals, credentials that cannot be set programmatically, and final product/business decisions.

## Safety / approval gates

Automation may do without approval:
- inspect repository, issues, pull requests, and CI
- fix formatting, lint, compile, test, and dependency-compatible issues
- make small UI/UX and reliability improvements on non-production branches
- add tests, docs, monitoring code, build checks, and developer tooling
- prepare pull requests and keep them green
- investigate failures and retry safe operations

Automation must ask before:
- merging to `main`
- first production deployment or changing production hosting
- spending money or enabling paid billing
- deleting or replacing user/cloud data
- weakening authentication, privacy, or security rules
- enabling monetization, payments, ads, affiliate links, or paid subscriptions
- publishing legal/terms/privacy changes
- accepting a customer commitment, contract, quote, or price

## Small-task batch

Keep these grouped and complete them opportunistically while larger work is in progress:
- fix analyzer/lint/test/build failures
- remove dead code and obvious duplication
- improve empty/loading/error states
- responsive overflow fixes
- accessibility basics (labels, focus order, contrast, keyboard usability)
- route/navigation consistency
- loading time and image-cache improvements that do not change architecture
- documentation and runbooks
- CI artifact retention and scheduled health builds
- dependency update PRs
- production-readiness checklists

## Big things — one at a time

1. **Finish and stabilize PR #3**
   - profiles
   - account/auth
   - cloud backup/restore
   - current UI redesign
   - CI green

2. **Automatic cloud sync**
   - offline-first local writes
   - queued cloud sync
   - retry/backoff
   - conflict-safe behavior
   - no manual backup button required for normal use

3. **Production deployment foundation**
   - free hosting first
   - deploy only from verified `main`
   - health checks
   - rollback path
   - production configuration separated from local development

4. **Production monitoring / self-healing**
   - uptime checks
   - build/deploy failure alerts
   - error capture
   - automatic low-risk fixes through non-production branches
   - owner notification only when a decision is needed

5. **Public product polish**
   - landing/onboarding
   - SEO/social metadata
   - shareable public lists/profiles where privacy-safe
   - diary polish
   - mobile/web responsiveness
   - provider/where-to-watch integration when appropriate

6. **Business / revenue layer**
   - prepare zero-cost lead generation and service funnel
   - keep monetization disabled until licensing, legal, work-authorization, payment, and platform-policy questions are explicitly approved
   - automate lead qualification and owner approval steps

## Current automation infrastructure

- Flutter CI on push/PR
- scheduled CI health build every 6 hours once workflow is on `main`
- verified web build artifact upload
- weekly Dependabot checks for Dart/Flutter and GitHub Actions
- ChatGPT Movie Tracker Autopilot condition watch runs hourly and should notify only when approval or intervention is actually needed

## Reliability principle

No software can literally be guaranteed to never stop. The design goal is: **no dependency on the owner's laptop, automatic retries, hosted execution, health monitoring, recoverable deployments, and notification only when human approval is necessary.**

## Pending owner policy decisions

Record the owner's answers here before enabling the corresponding automation:
- auto-merge policy
- auto-deploy policy
- production hosting choice
- cloud-sync conflict policy
- alert/approval behavior
- public launch scope
- business/revenue activation policy
