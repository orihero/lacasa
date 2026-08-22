/// Circular agent avatar with an initials fallback — mirrors
/// [ListingPhoto]'s "never show a broken-image glyph" rule, but round and
/// initials-based (an empty photo box reads oddly for a person). Every
/// agent-shaped surface in the app (Home's Top Agents rail, `agent-profile`,
/// `listing-detail`'s agent block) should use this rather than rolling its
/// own `ClipOval`/`Image.network`.
///
/// Promoted verbatim out of `features/home/widgets/agent_avatar.dart` — no
/// behavior change, only its address moved.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class AgentAvatar extends StatelessWidget {
  const AgentAvatar({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    this.size = 44,
  });

  final String? avatarUrl;
  final String fullName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // A name we don't have is not an initial — it's an empty slot. The
    // source's own uploader placeholder is a person silhouette on `--sunk`
    // (`.upl__ph` + `<i data-i="user-fill">`), which is what an unfilled
    // add-coworker form shows; a literal "?" read as a broken value.
    final Widget fallback = fullName.trim().isEmpty
        ? ColoredBox(
            color: colors.sunk,
            child: Center(
              child: Icon(Icons.person, size: size * 0.4, color: colors.faint),
            ),
          )
        : ColoredBox(
            color: colors.sunk,
            child: Center(
              child: Text(
                _initials(fullName),
                style: type.cardTitle.copyWith(
                  color: colors.ink2,
                  fontSize: size * 0.34,
                ),
              ),
            ),
          );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? fallback
            : Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }

  /// Only ever called with a non-empty name — the empty case renders the
  /// silhouette above instead of a placeholder character.
  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
