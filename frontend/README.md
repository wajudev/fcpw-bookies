# FCPW Bookies Frontend

Flutter app for the 1. FC Paulaner Wieden Tippspiel.

## Phase 3 Progress

**✅ Completed:**
- ✅ Supabase configuration and auth service
- ✅ Dark theme (Navy Blue + Gold + Slate)
- ✅ Login screen (email + password, German UI)
- ✅ Register screen (email + password + username validation)
- ✅ Auth wrapper with session management
- ✅ Home screen placeholder with bottom navigation
- ✅ Data models (User, Match, Prediction, UserSeasonStats)

**🚧 TODO (remaining Phase 3 work):**
- Games View (Spiele) with TabBar (KM/Reserve/Frauen)
- Match prediction inputs with 2-hour lock enforcement
- Golden boot picker (dropdown from `players` table)
- Leaderboard View (Rangliste) with season switcher
- Profile View (Profil) with stats
- Hall of Fame view (Ruhmeshalle)

## Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure Supabase**:
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` and add your credentials:
   - Get **SUPABASE_URL** from Supabase dashboard → Settings → API → Project URL
   - Get **SUPABASE_ANON_KEY** from Supabase dashboard → Settings → API → anon/public key
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...
   ```

## Running

```bash
flutter run          # Auto-selects available device
flutter run -d chrome     # Run in web browser (fastest for testing UI)
flutter run -d linux      # Linux desktop (requires build tools)
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart       # Supabase initialization
├── models/
│   ├── user_model.dart            # User & UserSeasonStats
│   └── match_model.dart           # Match & Prediction
├── services/
│   └── auth_service.dart          # Auth (login/register/signout)
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart      # Login UI
│   │   └── register_screen.dart   # Registration UI
│   └── home/
│       └── home_screen.dart       # Main app (3 tabs: Spiele/Rangliste/Profil)
├── theme/
│   └── app_theme.dart             # FCPW dark theme
└── main.dart                       # App entry + auth wrapper
```

## Features

### Auth
- **Email + Password** login via Supabase Auth
- **Username** stored in signup metadata → triggers `handle_new_user()` in DB (Phase 1)
- Auto-creates `users` row with unique username validation
- Session management via Supabase auth stream

### Theme
- **Navy Blue** (`#002d72`) primary
- **Gold** (`#EAB308`) accents
- **Slate** backgrounds (`#0F172A`, `#1E293B`)
- Dark mode optimized

## Next Steps

1. **Test auth flow** once Supabase credentials are added
2. **Build Games View** with live match fetching + prediction inputs
3. **Build Leaderboard** with real-time rankings
4. **Build Profile** with user stats

See `../organisational-stuffs/project-master-doc.md` for full Phase 3 spec.
