# Movie Tracker production setup

This production path is designed for **zero-spend operation** and for a public Flutter web build that does **not** expose the TMDB credential in browser JavaScript.

## Architecture

- **Frontend:** GitHub Pages (`https://rayat23.github.io/movie_tracker/`)
- **Accounts/data:** existing Firebase Authentication + Firestore project
- **TMDB access:** Cloudflare Worker proxy on the free tier
- **CI:** GitHub Actions
- **Health monitoring:** GitHub Actions every 15 minutes after production is enabled
- **Recovery:** one automatic redeploy attempt, then one incident issue if recovery fails

The production deployment remains disabled until the first launch is explicitly approved.

## 1. Deploy the TMDB proxy

Use the files under `edge/tmdb-proxy/`.

1. Create a free Cloudflare account if one is not already available.
2. Create/deploy a Worker using `edge/tmdb-proxy/worker.js`.
3. Configure `ALLOWED_ORIGINS` with:
   - `https://rayat23.github.io`
   - `http://localhost:8080` for local testing
4. Store the TMDB credential as a Worker secret. Never commit it to GitHub.
   - Preferred: `TMDB_BEARER_TOKEN`
   - Also supported: `TMDB_API_KEY`
5. Copy the deployed Worker base URL, for example `https://movie-tracker-tmdb.<account>.workers.dev`.

The proxy only permits the TMDB routes currently used by Movie Tracker and caches read responses to reduce upstream requests.

## 2. Configure GitHub repository variables

Open **GitHub → Rayat23/movie_tracker → Settings → Secrets and variables → Actions → Variables**.

Add:

- `TMDB_PROXY_BASE_URL` = the deployed Worker URL
- `PRODUCTION_DEPLOY_ENABLED` = `false` initially

Do not place the TMDB credential in a normal repository variable. Keep it only in the Worker secret store.

## 3. Enable GitHub Pages

Open **Settings → Pages** and select **GitHub Actions** as the deployment source if GitHub asks for a source.

The production workflow builds Flutter with the `/movie_tracker/` base path and deploys the verified output to GitHub Pages.

## 4. Authorize the production domain in Firebase

In Firebase Authentication, add `rayat23.github.io` to **Authorized domains**.

The public Firebase web configuration is embedded in the web build by design. Authentication + Firestore Security Rules remain the security boundary.

## 5. First production launch

The first launch is intentionally gated.

After the owner approves the first launch:

1. Change `PRODUCTION_DEPLOY_ENABLED` to `true`.
2. Run **Actions → Production Deploy → Run workflow** once.
3. Confirm `https://rayat23.github.io/movie_tracker/health.json` returns JSON containing `"status":"ok"`.
4. Confirm sign-up/sign-in and cloud sync work on the public domain.
5. Confirm movie and TV browsing works through the Worker proxy.

## 6. What becomes automatic after launch

Once `PRODUCTION_DEPLOY_ENABLED=true`:

- a successful Flutter CI run caused by a push to `main` automatically deploys production;
- scheduled CI health builds do not redeploy production unnecessarily;
- production health is checked every 15 minutes;
- transient failures are retried;
- a persistent failure triggers one safe redeploy of `main`;
- if production is still unhealthy, one GitHub incident issue is opened/updated for human attention.

## Security and cost guardrails

- No production build should contain the TMDB API key/token.
- No billing upgrade is required by this setup.
- Do not enable paid Movie Tracker monetization until TMDB commercial-use/licensing requirements are resolved.
- Do not weaken Firestore rules to make deployment easier.
- Do not enable a paid service, domain, or cloud product without owner approval.
