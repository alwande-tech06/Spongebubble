import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sb_ui/sb_ui.dart';

import 'router.dart';

void main() => runApp(const ProviderScope(child: AdminApp()));

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SpongeBubble Admin',
      debugShowCheckedModeBanner: false,
      theme: sbTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
