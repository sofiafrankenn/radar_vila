import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/app.dart';
import 'package:radar_vila/data/local/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.create();
  runApp(RadarVilaApp(store: store));
}
