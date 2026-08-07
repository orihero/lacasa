/// The Top Districts rail — a hardcoded local list (build spec: "no
/// backing entity anywhere in SCREENS.md §4"), so no loading/error/empty
/// states apply (build spec's table: "N/A — static local list, no network
/// call"). Every tile navigates to the Search tab unconditionally, exactly
/// matching the mockup's own unconditional `data-go="listing-search"`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class _DistrictSpec {
  const _DistrictSpec(this.name, this.gradient);
  final String name;
  final Gradient gradient;
}

const List<_DistrictSpec> _districts = [
  _DistrictSpec(
    'Chilonzor',
    LinearGradient(colors: [Color(0xFFB5804A), Color(0xFF5A3B1E)]),
  ),
  _DistrictSpec(
    'Yunusobod',
    LinearGradient(colors: [Color(0xFF4A87B5), Color(0xFF1E3B5A)]),
  ),
  _DistrictSpec(
    'Sergeli',
    LinearGradient(colors: [Color(0xFF6FA55B), Color(0xFF2C4022)]),
  ),
  _DistrictSpec(
    'Mirobod',
    LinearGradient(colors: [Color(0xFFB55A8B), Color(0xFF5A1E40)]),
  ),
];

class TopDistrictsRail extends StatelessWidget {
  const TopDistrictsRail({super.key});

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Top Districts',
          linkLabel: 'Explore',
          onLink: () => context.go(RoutePaths.search),
        ),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            itemCount: _districts.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final district = _districts[index];
              return GestureDetector(
                key: ValueKey('district-${district.name}'),
                onTap: () => context.go(RoutePaths.search),
                child: Container(
                  width: 78,
                  height: 96,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    gradient: district.gradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 8,
                        child: Text(
                          district.name,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: type.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
