<!-- cspell:ignore Drogon drogon jsoncpp trantor Nanode Linode randoeats Randoeats googleusercontent buildx nproc logrotate copytruncate -->

# RandoEats BFF

A Backend-for-Frontend for the RandoEats Flutter app, written in **C++ / Drogon**.
It is the only thing that talks to the Google Places API (New): the app calls the
BFF, the BFF calls Google. This keeps the API key off the client, enables shared
caching, and gives the app a stable, normalized response contract.

> Full design rationale lives in [`../RANDOEATS_PROJECT.md`](../RANDOEATS_PROJECT.md).
> Reviews are intentionally **not** implemented yet (cost) — there's a clean seam
> to add a `/reviews` endpoint later.

## Architecture (§0 rule)

```
Flutter App → RandoEats BFF (Drogon/C++) → Google Places API (New)
                   │
                   ├── InMemoryCache (TTL + LRU bounded)
                   └── MetricsLogger (JSONL)
```

**`GooglePlacesClient` is the only component permitted to make upstream Google
calls.** Controllers → Services → {`GooglePlacesClient`, `ICache`}. Every upstream
call documents its billing SKU tier in a comment.

## Endpoints (`/api/v1`)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/restaurants/nearby` | **List view.** `lat`,`lng` (required); `q` (keyword/cuisine/mood; empty = browse); `radius` (m, default 5000, max 50000); `max` (default 20, max 60 — paginated); filters: `open=true`, `min_rating`, `price` (CSV of 1–4), and atmosphere `beer`/`wine`/`patio`/`group`/`parking` (`=true`). → `{ "restaurants": [...] }` |
| GET | `/restaurants/{place_id}` | **Detail view** — single normalized restaurant with the full field set. 404 if not found. |
| GET | `/restaurants/{place_id}/photo` | `photo_ref` (required), `max_width` (default 400, max 1600). Proxies image **bytes**. |
| GET | `/health` | `{"status":"ok","version":"..."}` |

**Normalization** (missing fields omitted; `photoRefs` always present):
- **List** (`/nearby`, lean/Enterprise): `id, name, address, location{lat,lng}, rating, ratingCount, priceLevel (0–4), type, openNow, photoRefs[]`. Atmosphere fields are also fetched + returned **only when an atmosphere filter is active** (it's then filtered client-side, since Places can't filter these upstream).
- **Detail** (`/{id}`, full/Enterprise+Atmosphere): the above **plus** `phone, website, weekdayHours[], editorialSummary, servesBeer, servesWine, outdoorSeating, goodForGroups, hasParking`.

Server-side filters (`open`/`min_rating`/`price`) and pagination (up to ~60 via `nextPageToken`) are handled in the BFF, mirroring the Flutter client it replaces.

## Configuration

Copy the template and fill in the key (the real `config.json` is git-ignored —
**never commit it**):

```bash
cp config.example.json config.json
# edit config.json: set places_api_key
```

| Key | Meaning |
|-----|---------|
| `places_api_key` | Google Places API (New) key. **Restrict it by IP to the Linode.** |
| `port` | Listen port (default 8848) |
| `threads` | Drogon worker threads (1 is plenty on a Nanode) |
| `cache_max_entries` | LRU bound (default 2000) — keeps RAM in check on the 1 GB box |
| `nearby_ttl_seconds` / `details_ttl_seconds` | Cache TTLs (1h / 6h). Keep well under Google's 30-day caching limit. |
| `metrics_log_path` | JSONL metrics file |
| `allowed_origins` | CORS allow-list for the web client |

## Build & run

### Local (dev compile-check only)

Apple Silicon Macs are ARM; the Linode is x86-64, so a local binary **won't run on
the server** — local builds are just for fast compile-checking.

```bash
brew install drogon            # one-time
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
./build/randoeats_bff config.json
```

### Docker (the deployable x86-64 artifact)

```bash
docker buildx build --platform linux/amd64 -t randoeats-bff:latest .
```

**Run as a container** (mount config + log dir; nothing secret is baked in):

```bash
docker run -d --name randoeats-bff -p 8848:8848 \
  -v /etc/randoeats/config.json:/app/config.json:ro \
  -v /var/log/randoeats:/var/log/randoeats \
  randoeats-bff:latest
```

**Or run the binary natively under systemd** (lighter on a shared 1 GB box —
no Docker daemon). Extract the binary from the image, drop it at
`/opt/randoeats/randoeats_bff`, and use a unit like:

```ini
[Unit]
Description=RandoEats BFF
After=network.target

[Service]
User=randoeats
ExecStart=/opt/randoeats/randoeats_bff /etc/randoeats/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Logging & rotation

`MetricsLogger` keeps the log file open, so logrotate must use `copytruncate`.
`/etc/logrotate.d/randoeats`:

```
/var/log/randoeats/metrics.jsonl {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    create 640 randoeats randoeats
}
```

Create the dir first: `sudo mkdir -p /var/log/randoeats && sudo chown randoeats:randoeats /var/log/randoeats`.

## Metrics analysis

```bash
python3 tools/analyze_metrics.py /var/log/randoeats/metrics.jsonl
```

Prints p50/p95/p99 latency and cache hit rate, overall and per upstream endpoint.
Run before/after enabling caching to quantify the win.

## Pre-deploy checklist

- [ ] Places API **(New)** enabled in Google Cloud (not legacy)
- [ ] Server key created and **IP-restricted to the Linode**
- [ ] Billing budget alert + daily quota cap set
- [ ] Port 8848 free on the Linode (shared box)
- [ ] `/var/log/randoeats/` created with correct ownership
- [ ] `config.json` placed outside the repo, not committed
