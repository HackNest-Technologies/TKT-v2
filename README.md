# The Kingdom Trybe (TKT)

An online church for young people: livestream worship, Trybe community and support.
Rails 8.1 · PostgreSQL 16 · Hotwire · Devise · Pundit.

**Status:** Stage 1 (foundation), the landing page and Stage 3 (accounts) are built and tested.
Other pages show a "being built" notice. Content on the landing page (stream, Trybes, testimonies,
blog post) is sample data from the design — testimonies must not go live without consent.

---

## 1. Run it on your computer

Requirements: Ruby 3.3.6, PostgreSQL 16, Google Chrome (for browser tests).

```bash
git clone <your repo> tkt && cd tkt
bundle install
cp .env.example .env            # then edit DATABASE_URL if needed
export $(grep -v '^#' .env | xargs)   # or use direnv / dotenv
bin/rails db:prepare            # creates and migrates the database
bin/rails server                # http://localhost:3000
```

Emails in development are saved to `tmp/mails/` — open the newest file to click the confirmation link.

## 2. Tests and checks

```bash
bin/rails test:all      # unit, integration and browser tests (incl. axe accessibility checks)
bin/brakeman            # static security analysis
bin/bundler-audit       # known-vulnerable gems
bin/importmap audit     # known-vulnerable JS packages
bin/rubocop             # style
```

CI (`.github/workflows/ci.yml`) runs all of these plus a secret scan (gitleaks) on every push.

## 3. Configuration

All settings and secrets come from environment variables — see `.env.example`.
There is **no** `config/master.key` or credentials file; never commit secrets.

| Variable | Needed for |
| --- | --- |
| `SECRET_KEY_BASE` | Always in production (`bin/rails secret` makes one) |
| `DATABASE_URL` | Always |
| `SINGLE_DATABASE=true` | Single-database hosting (Render free tier) |
| `CACHE_/QUEUE_/CABLE_DATABASE_URL` | Multi-database hosting (Hostinger) |
| `APP_HOSTS` | Your domain(s); requests for other hosts are refused |
| `SMTP_*`, `MAIL_FROM` | Sending confirmation/reset emails |
| `GOOGLE_CLIENT_ID/SECRET` | "Continue with Google" (hidden until set) |
| `PREVIEW_PASSWORD` | Puts the whole site behind a password (user `tkt`) |
| `ALLOW_UNCONFIRMED_ACCESS=true` | Previews without email only |

## 4. Preview on Render (free)

1. Push this repository to GitHub.
2. In Render: **New → Blueprint**, pick the repository. Render reads `render.yaml` and creates
   the web service `tkt-preview` and the database `tkt-preview-db` (Frankfurt).
3. When asked, set `PREVIEW_PASSWORD` (choose a strong one). Leave the SMTP and Google fields blank for now.
4. Wait for the first deploy, then open `https://tkt-preview.onrender.com` (user `tkt`, your password).

Free-tier limits: the service sleeps after 15 minutes idle (about a minute to wake), and the free
database **expires 30 days after creation** — upgrade it in Render if you want to keep preview data.

## 5. Production on the Hostinger VPS (Kamal)

Not yet done — happens after staging sign-off. Outline:

```bash
# on your computer, with Docker and SSH access to the VPS
export TKT_WEB_HOST=<vps ip> TKT_APP_HOST=<your domain>
export SECRET_KEY_BASE=... POSTGRES_PASSWORD=...     # from your password manager
bin/kamal setup        # first time: installs Docker, Postgres accessory, deploys
bin/kamal deploy       # later releases
```

### Database migrations
Migrations run automatically on start (`bin/rails db:prepare` in `bin/docker-entrypoint` and Render's
start command). Write migrations so the previous release still works with the new schema
(add columns first, remove them in a later release).

### Rollback
- **Render:** Dashboard → service → Events → pick an earlier deploy → *Rollback*.
- **Kamal:** `bin/kamal app containers` to list versions, then `bin/kamal rollback <version>`.
- If a migration must be undone: `bin/kamal app exec 'bin/rails db:rollback'` — only for migrations
  written to be reversible, and only after taking a backup.

## 6. Security notes

- Strict Content Security Policy (no inline scripts/styles), HSTS, frame denial, Permissions-Policy.
- Sign-in: Devise 5 with lockout after 10 failures, 12+ character passwords, email confirmation,
  same response whether or not an account exists, rate limits per IP and per account.
- Every sign-in is a server-side session record: members can see devices and sign them out;
  password changes sign out every other device.
- Sign-up requires age 16+ and explicit consent to storing religious-affiliation data.
- Members can download their data and delete their account (purged after 30 days).

See the plan document for the threat model, privacy notes and outstanding launch blockers.
