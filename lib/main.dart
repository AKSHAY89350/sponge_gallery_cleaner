import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/gallery_provider.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpongeApp());
}

class SpongeApp extends StatelessWidget {
  const SpongeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GalleryProvider(),
      child: MaterialApp(
        title: 'Sponge - Gallery Cleaner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        ),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _permissionsChecked = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final provider = context.read<GalleryProvider>();
    final granted = await provider.checkPermissions();
    setState(() {
      _permissionsChecked = true;
      _permissionsGranted = granted;
    });
    if (granted) {
      provider.loadGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }
    if (!_permissionsGranted) {
      return PermissionScreen(onGranted: () {
        setState(() => _permissionsGranted = true);
        context.read<GalleryProvider>().loadGallery();
      });
    }
    return const HomeScreen();
  }
}
