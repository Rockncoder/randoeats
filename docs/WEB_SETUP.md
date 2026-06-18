# Getting the Web App Working (Google Places API key)

The web build (randoeats.com, deployed to Cloudflare Pages) currently comes up
but returns **no restaurants**. This is because the Google Places API key is
**not injected into the web build**.

`lib/services/places_service.dart` reads the key at compile time:

```dart
static const _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
```

Locally and for mobile we pass it via `--dart-define-from-file=.env`. But
`.github/workflows/deploy-web.yml` builds web with **no `--dart-define`**, so on
the web `_apiKey` is an empty string and every Places request fails.

There are two parts: (1) inject a key into the web build, and (2) make sure that
key actually works from a browser (CORS + restrictions).

---

## ⚠️ Important: web has two extra constraints mobile doesn't

1. **The key ships to the browser.** Anything in a web build is public. A web
   Places key MUST be locked down with an **HTTP referrer restriction**
   (`randoeats.com/*`) so it can't be reused elsewhere. Do **not** reuse the
   unrestricted server/mobile key.
2. **CORS.** The app calls `https://places.googleapis.com` directly. Browser
   (cross-origin) calls to the Places API can be blocked by CORS. If, after
   injecting the key, the browser console shows CORS errors, the direct-call
   approach won't work on web and you need the **server proxy** described in
   [`BACKEND_PROXY_PLAN.md`](BACKEND_PROXY_PLAN.md) (recommended end state
   anyway, since it also keeps the key off the client). Mobile is unaffected.

---

## Step 1 — Create a web-restricted Places API key

In the [Google Cloud Console](https://console.cloud.google.com/) for the
randoeats project:

1. **APIs & Services → Library** → enable **Places API (New)** (and **Maps
   JavaScript API** if the web app renders maps).
2. **APIs & Services → Credentials → Create credentials → API key**.
3. Edit the new key:
   - **Application restrictions → Websites (HTTP referrers)** and add:
     - `https://randoeats.com/*`
     - `https://*.randoeats.com/*`
     - `https://<your-cloudflare-pages-subdomain>.pages.dev/*` (for preview)
     - `http://localhost:*/*` (for local `flutter run -d chrome`)
   - **API restrictions → Restrict key** → select **Places API (New)** (and
     Maps JavaScript API if used).
4. Copy the key value.

> Keep this **separate** from the mobile/server key. It's a public, referrer-
> locked, web-only key.

## Step 2 — Add the key as a GitHub Actions secret

The deploy workflow runs in the `production` environment, so add the secret
there (or as a repo secret).

**Via the GitHub UI:** Repo → **Settings → Secrets and variables → Actions** →
(Environment `production`) → **New secret**:
- Name: `GOOGLE_PLACES_API_KEY`
- Value: *the web key from Step 1*

**Or via the CLI** (run it yourself so the value isn't logged — in this session
prefix with `!`):

```bash
gh secret set GOOGLE_PLACES_API_KEY --env production
# paste the key when prompted
```

## Step 3 — Inject the key into the web build

Edit `.github/workflows/deploy-web.yml` so the build step passes the key:

```yaml
      - name: Build Flutter Web
        run: |
          flutter build web \
            --release \
            -t lib/main_production.dart \
            --dart-define=GOOGLE_PLACES_API_KEY=${{ secrets.GOOGLE_PLACES_API_KEY }}
```

(That's the only change — add the trailing `--dart-define` line.)

## Step 4 — Redeploy

Either push to `main` (the workflow runs on changes under `lib/**`,
`pubspec.yaml`, or the workflow file) or trigger it manually:

```bash
gh workflow run deploy-web.yml --ref main
```

## Step 5 — Verify

1. Open https://randoeats.com, open the browser **DevTools → Network/Console**.
2. Spin / load results.
   - **Restaurants appear** → done. ✅
   - **403 / "API key not valid" / "RefererNotAllowed"** → the key restriction
     or API enablement is wrong (revisit Step 1; confirm the live origin is in
     the referrer list).
   - **CORS errors** (`No 'Access-Control-Allow-Origin'`) → direct browser calls
     are blocked; switch web to the proxy in
     [`BACKEND_PROXY_PLAN.md`](BACKEND_PROXY_PLAN.md).

---

## Local web testing

You can test the web build locally with your existing `.env`:

```bash
flutter run -d chrome --dart-define-from-file=.env -t lib/main_staging.dart
# or a release build:
flutter build web -t lib/main_production.dart --dart-define-from-file=.env
```

If it works locally but not on randoeats.com, the difference is almost always
the **referrer restriction** (localhost is allowed, the live origin isn't) or
the **missing GitHub secret**.

---

## Notes / recommended end state

- Photos are loaded via a URL that embeds the key, so the web key is also
  visible in image requests — another reason to keep it referrer-restricted.
- The durable fix for web (and for key safety generally) is the **backend
  proxy** in [`BACKEND_PROXY_PLAN.md`](BACKEND_PROXY_PLAN.md): the browser calls
  our API, which holds the key server-side and resolves CORS. Once that exists,
  the web build needs no Places key at all.
