/// Barrel export for the Direction E "Liquid Glass" design-token theme.
///
/// Typical usage from `lib/app.dart`:
/// ```dart
/// import 'theme/theme.dart';
///
/// MaterialApp(
///   theme: AppTheme.light(),
///   darkTheme: AppTheme.dark(),
///   themeMode: ThemeMode.system, // or app-state-driven override
///   ...
/// )
/// ```
/// and from any widget:
/// ```dart
/// import 'theme/theme.dart';
///
/// final colors = Theme.of(context).extension<LaCasaColors>()!;
/// final type = Theme.of(context).extension<LaCasaTypography>()!;
///
/// GlassSurface(
///   variant: GlassVariant.onSurface,
///   borderRadius: BorderRadius.circular(AppRadii.card),
///   padding: const EdgeInsets.all(AppSpacing.lg),
///   child: Text('Listing', style: type.cardTitle.copyWith(color: colors.ink)),
/// )
/// ```
library;

export 'app_colors.dart';
export 'app_radii.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';
export 'glass_surface.dart';
export 'glass_theme_extension.dart';
