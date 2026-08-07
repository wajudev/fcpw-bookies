# Deployment Guide

## Prerequisites

1. **GitHub Repository**: Push this code to GitHub
2. **Supabase Project**: Already set up
3. **GitHub Actions**: Free for public repos, 2000 min/month for private

## Setup Steps

### 1. Configure GitHub Secrets

Go to your GitHub repo → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:
- `SUPABASE_URL`: Your Supabase project URL (e.g., `https://xxxxx.supabase.co`)
- `SUPABASE_SERVICE_KEY`: Your Supabase service role key (from Supabase Settings → API)

⚠️ **Use SERVICE KEY, not ANON KEY** - scrapers need full database access.

### 2. Enable GitHub Pages

1. Go to repo Settings → Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` / `root`
4. Save

### 3. Configure Flutter Web Environment

Update `frontend/lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR-ANON-KEY-HERE';
}
```

⚠️ **Use ANON KEY for frontend** - this is public and safe for client-side.

### 4. Test Workflows Manually

1. Go to Actions tab
2. Select "Scrape WFV Matches"
3. Click "Run workflow"
4. Check logs for success

### 5. Deploy Frontend

```bash
git add .
git commit -m "Add deployment workflows"
git push origin main
```

This will automatically:
- Build Flutter web app
- Deploy to GitHub Pages
- Your app will be live at: `https://YOUR-USERNAME.github.io/fcpw-bookies/`

## Automated Schedules

Once live, scrapers run automatically:
- **WFV Matches**: Every 12 hours (00:00, 12:00 UTC)
- **OEFB Standings**: Daily at 02:00 UTC

## Custom Domain (Optional)

1. Buy a domain (e.g., Namecheap, Google Domains)
2. In repo Settings → Pages → Custom domain
3. Add your domain and configure DNS:
   - Type: `CNAME`
   - Name: `@` or `www`
   - Value: `YOUR-USERNAME.github.io`

## Costs

- GitHub Actions: **Free** (2000 min/month, ~40 scrapes)
- GitHub Pages: **Free**
- Supabase: **Free** (500MB DB, 50k users)
- Total: **$0/month** for 100 users

## Monitoring

- Check workflow runs: Actions tab
- View logs: Click any workflow run
- Manual trigger: Actions → Select workflow → "Run workflow"

## Troubleshooting

### Scraper fails
- Check logs in Actions tab
- Verify secrets are set correctly
- Test locally: `cd backend && go run cmd/scrape-wfv/main.go`

### Frontend not deploying
- Check build logs in Actions
- Verify Flutter version matches (3.24.0)
- Test build locally: `cd frontend && flutter build web`

### Database connection fails
- Verify `SUPABASE_URL` has no trailing slash
- Check service key has full permissions
- Test connection: Supabase dashboard → API docs → Test connection
