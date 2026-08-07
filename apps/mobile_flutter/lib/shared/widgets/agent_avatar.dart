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

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? ColoredBox(
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
              )
            : Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
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
                ),
              ),
      ),
    );
  }

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
