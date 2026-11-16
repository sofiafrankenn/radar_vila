import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/widgets/state_views.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: 'Não encontramos esta tela',
        message: 'O link pode estar incompleto.',
        action: FilledButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text('Voltar ao início'),
        ),
      ),
    );
  }
}
