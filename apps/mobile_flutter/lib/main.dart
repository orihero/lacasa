/// App entry point: bootstraps the Flutter binding, wraps the app tree in a
/// [ProviderScope] so every widget can read Riverpod providers, and hands
/// off to [App] for theme/navigation wiring.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}
