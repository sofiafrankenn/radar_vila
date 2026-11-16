import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/screens/consent/consent_screen.dart';
import 'package:radar_vila/screens/home/home_shell.dart';

/// Sem consentimento explícito, o app não passa da tela de consentimento.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final consent =
        context.select<SettingsProvider, bool>((s) => s.consentGiven);
    return consent ? const HomeShell() : const ConsentScreen();
  }
}
