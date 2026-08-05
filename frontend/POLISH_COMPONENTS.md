# Polish & UX Components

New reusable widgets to improve app polish and user experience.

## Components Created

### 1. Season Selector (`lib/widgets/season_selector.dart`)
**Usage:**
```dart
SeasonSelector(
  currentSeasonName: '2026/27',
  seasons: seasons,
  onSeasonChanged: (seasonId) {
    // Handle season change
  },
)
```
- Shows dropdown only if multiple seasons exist
- Checkmark for current season
- Purple themed styling

### 2. Loading Shimmer (`lib/widgets/loading_shimmer.dart`)
**Usage:**
```dart
// Generic shimmer
LoadingShimmer(width: 100, height: 20, borderRadius: 8)

// Pre-built shimmers
MatchCardShimmer()
LeaderboardRowShimmer()
```
- Animated gradient loading effect
- Pre-built components for common layouts
- Replace `CircularProgressIndicator()` for better UX

### 3. Empty States (`lib/widgets/empty_state.dart`)
**Usage:**
```dart
// Empty state
EmptyState(
  icon: Icons.sports_soccer,
  title: 'No matches yet',
  message: 'Matches will appear here when available',
  actionLabel: 'Refresh',
  onAction: _loadData,
)

// Error state
ErrorState(
  title: 'Connection Error',
  message: 'Could not load data',
  onRetry: _loadData,
)
```
- Consistent empty/error states across app
- Optional action buttons

### 4. Snackbar Helper (`lib/utils/snackbar_helper.dart`)
**Usage:**
```dart
SnackbarHelper.showSuccess(context, 'Prediction saved!');
SnackbarHelper.showError(context, 'Failed to save');
SnackbarHelper.showInfo(context, 'Match locked');
SnackbarHelper.showWarning(context, 'Deadline approaching');
```
- Consistent snackbar styling
- Icons for each type
- Floating snackbars with rounded corners

### 5. Match Detail Sheet (`lib/widgets/match_detail_sheet.dart`)
**Usage:**
```dart
MatchDetailSheet.show(context, match, prediction);
```
- Bottom sheet with match details
- Shows prediction and points awarded
- Match info (squad, matchweek, deadline, status)
- Draggable and scrollable

## How to Use in Existing Screens

### Replace Loading Indicators
**Before:**
```dart
if (_isLoading) return CircularProgressIndicator();
```

**After:**
```dart
if (_isLoading) return ListView(
  children: List.generate(5, (_) => MatchCardShimmer()),
);
```

### Replace Empty States
**Before:**
```dart
if (matches.isEmpty) return Text('No matches');
```

**After:**
```dart
if (matches.isEmpty) return EmptyState(
  icon: Icons.sports_soccer,
  title: 'No matches',
  message: 'Matches will appear soon',
);
```

### Replace Snackbars
**Before:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Saved!')),
);
```

**After:**
```dart
SnackbarHelper.showSuccess(context, 'Saved!');
```

### Add Match Detail
**Before:**
```dart
onTap: () {
  // Navigate or show dialog
}
```

**After:**
```dart
onTap: () {
  MatchDetailSheet.show(context, match, prediction);
}
```

## Next Steps

To fully integrate:
1. Replace CircularProgressIndicator with shimmers
2. Use EmptyState/ErrorState consistently
3. Replace all SnackBar calls with SnackbarHelper
4. Add MatchDetailSheet to match cards
5. Add SeasonSelector to screens (when multi-season support ready)
