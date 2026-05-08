# Flutter Redesign Foundation

## Goal

Port the `otlplus-web-v4` design tokens into Flutter so mobile surfaces can share the same color and typography semantics. All new code should consume tokens via `context.colors` and `context.texts`; legacy `OTLColor` / global `TextStyle` exports are kept for backwards compatibility only and will be removed once every surface is migrated.

## Usage

```dart
import 'package:otlplus/theme/context_ext.dart';

Widget build(BuildContext context) {
  final colors = context.colors;
  final texts  = context.texts;
  return Container(
    color: colors.backgroundSectionDefault,
    child: Text('hello', style: texts.normalBold),
  );
}
```

If a helper method needs access to tokens but doesn't have `BuildContext`, add `BuildContext context` as its first parameter and thread it from the nearest `build()` scope.

## Color token mapping (authoritative)

This is what the three coordinated redesign PRs (`home-timetable`, `account-settings`, `search-dictionary`, `course-lecture-detail`, `reviews`) actually apply. Some mappings are context-dependent; use the "usage hint" column to pick the correct token.

| Legacy `OTLColor` | New `AppColorScheme` | Usage hint |
| --- | --- | --- |
| `OTLColor.gray0` (`#000000`) | `context.colors.textDark` | Foreground text on light surfaces |
| `OTLColor.gray3` (`#333333`) | `context.colors.textDefault` | Primary body text |
| `OTLColor.gray5` (`#555555`) | `context.colors.textLight` | Secondary text |
| `OTLColor.gray6` (`#666666`) | `context.colors.textLighter` | Tertiary text *(drift: web token = `#888888`)* |
| `OTLColor.gray75` (`#757575`) | `context.colors.textLighter` | Tertiary text |
| `OTLColor.grayA` (`#AAAAAA`) | `context.colors.textDisable` **or** `context.colors.textPlaceholder` | Disabled text / input hint text |
| `OTLColor.grayD` (`#DDDDDD`) | `context.colors.lineDark` **or** `context.colors.lineBlock` | Prominent dividers / block borders |
| `OTLColor.grayE` (`#EEEEEE`) | `context.colors.lineDefault` | Subtle dividers *(drift: web token = `#E8E8E8`)* |
| `OTLColor.grayF` (`#FFFFFF`) | `context.colors.backgroundSectionDefault` **or** `context.colors.textBright` | Card background / foreground on dark |
| `OTLColor.pinksLight` (`#F9F0F0`) | `context.colors.backgroundPageDefault` | Page background |
| `OTLColor.pinksMain` (`#E54C65`) | `context.colors.highlightDefault` | Primary accent |
| `OTLColor.pinksSelected` (`#E54C64`) | `context.colors.highlightDefault` | Selected accent (same value with a 1-hex drift) |

Tiles for the timetable grid are mapped ordinally from `OTLColor.blockColors[0..15]`:

| Legacy index | New token |
| --- | --- |
| `0`, `1` | `tileTimetableRed1`, `tileTimetableRed2` |
| `2`, `3` | `tileTimetableOrange1`, `tileTimetableOrange2` |
| `4`, `5` | `tileTimetableYellow1`, `tileTimetableYellow2` |
| `6`, `7`, `8` | `tileTimetableGreen1`, `tileTimetableGreen2`, `tileTimetableGreen3` |
| `9`, `10` | `tileTimetableBlue1`, `tileTimetableBlue2` |
| `11`, `12`, `13` | `tileTimetablePurple1`, `tileTimetablePurple2` (13 reuses Purple2 — drift) |
| `14`, `15` | `tileTimetablePink1`, `tileTimetablePink2` |

### Kept as `OTLColor` (marked `// legacy:`)

Some legacy values don't have a direct web token yet. Redesigned surfaces keep them with a `// legacy:` comment so reviewers know the drift is intentional:

| Legacy `OTLColor` | Why kept |
| --- | --- |
| `OTLColor.barrier` (`#40000000`) | Modal scrim; no direct web token. |
| `OTLColor.pinksSub` (`#F6C5CD`) | Soft accent used in a few places; no direct web token. |
| `OTLColor.red` (`#FF453A`) | System red (iOS-ish); web has no generic "error red" token. |

## Text style mapping

| Legacy global style (`lib/constants/text_styles.dart`) | New token (`context.texts.*`) | Notes |
| --- | --- | --- |
| `labelRegular` (12 / lh 1.4) | `small` | Size matches; line-height drift: 1.4 → 1.25 |
| `labelBold` | `smallBold` | |
| `bodyRegular` (14 / lh 1.6) | `normal` | Line-height drift: 1.6 → 1.25 |
| `bodyBold` | `normalBold` | |
| `titleRegular` (16 / lh 1.6) | `big` | Line-height drift: 1.6 → 1.25 |
| `titleBold` | `bigBold` | |
| `headlineRegular` (18) | `big` | **Size drift**: 18 → 16 (web scale caps earlier). |
| `headlineBold` | `bigBold` | Same size drift. |
| `displayRegular` (20) | `bigger` | Size matches. |
| `displayBold` | `biggerBold` | |

Web `fonts.ts` defines `lineHeight` in absolute pixels; Flutter `TextStyle.height` is a multiplier. All `AppTextTheme` styles pre-compute `flutterHeight = webLineHeight / fontSize`, so consumers don't need to worry about it.

## PR roadmap

| Stage | PR | Target | Description |
| --- | --- | --- | --- |
| 1 | **foundation** (this) | `main` | Tokens, fonts, theme extensions, `AppTheme` wiring, `login_page` proof. |
| 2 | home + timetable | `main` (after stage 1 merge) | 11 widgets/pages migrated. |
| 3 | account + settings | `main` | 4 pages migrated. |
| 4 | search + dictionary | `main` | 8 files (pages + widgets) migrated. |
| 5 | course + lecture detail | `main` | 6 files migrated. |
| 6 | reviews | `main` | 7 files migrated. |
| 7 | shared primitives *(future)* | `main` | `otl_scaffold.dart`, `responsive_button.dart`, `otl_dialog.dart`, `dropdown.dart`, `pop_up.dart` — cross-cutting so deferred. |
| 8 | dark-mode enablement *(future)* | `main` | `AppColorScheme.dark()` is already wired; flip `themeMode` to `ThemeMode.system` once no hard-coded light colors remain in native-adjacent surfaces (ChannelTalk, home-screen widgets, watchOS). |

Stages 2–6 are independent feature branches cut from `origin/main` and opened as draft PRs. Each will rebase onto `main` and flip to *Ready* after stage 1 merges.

## Conventions reminder

- No `as dynamic`, no `// ignore:`, no `@ts-ignore`-style suppressions.
- Never delete legacy `OTLColor.*` or `*Regular` / `*Bold` exports; other surfaces still import them. Migration happens PR-by-PR.
- When editing a file that already uses the new tokens, add `import 'package:otlplus/theme/context_ext.dart';` exactly once.
- When a `StatelessWidget` helper method needs tokens but lacks `BuildContext`, pass `BuildContext context` as its first parameter.
