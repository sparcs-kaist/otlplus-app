# Flutter Redesign Foundation

## Goal

Port the `otlplus-web-v4` design tokens into Flutter so mobile surfaces can share the same color and typography semantics.

## Usage

- `context.colors.textDefault`
- `context.texts.normalBold`

## Color token mapping

| Legacy `OTLColor` | New `AppColorScheme` |
| --- | --- |
| `OTLColor.gray0` | `context.colors.textDark` |
| `OTLColor.gray3` | `context.colors.textDefault` |
| `OTLColor.gray5` | `context.colors.textLight` |
| `OTLColor.grayA` | `context.colors.textPlaceholder` |
| `OTLColor.grayD` | `context.colors.lineBlock` |
| `OTLColor.grayE` | `context.colors.backgroundButtonDefault` |
| `OTLColor.grayF` | `context.colors.backgroundSectionDefault` |
| `OTLColor.pinksLight` | `context.colors.backgroundPageDefault` |
| `OTLColor.pinksMain` | `context.colors.highlightDefault` |
| `OTLColor.pinksSelected` | `context.colors.backgroundTileHighlight` |

## Text style mapping

| Legacy global style | New text token |
| --- | --- |
| `labelRegular` | `context.texts.small` |
| `labelBold` | `context.texts.smallBold` |
| `bodyRegular` | `context.texts.normal` |
| `bodyBold` | `context.texts.normalBold` |
| `titleRegular` | `context.texts.big` |
| `titleBold` | `context.texts.bigBold` |
| `headlineRegular` | `context.texts.bigger` |
| `headlineBold` | `context.texts.biggerBold` |
| `displayRegular` | `context.texts.bigger` |
| `displayBold` | `context.texts.biggerBold` |

## PR roadmap

1. Foundation tokens, theme extensions, app theme wiring, and login proof screen.
2. Home + timetable redesign consumption.
3. Account + settings redesign consumption.
4. Future screen migrations.
5. Future dark-mode enablement (`AppColorScheme.dark()` is ready; app remains light-only in this PR).
