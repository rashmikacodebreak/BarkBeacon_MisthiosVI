import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'my_pets_page.dart';
import 'missing_pets_page.dart';
import 'pet_map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BarkBeaconApp());
}

const _brandOrange = Color(0xFFFF5B00);
const _brandNavy = Color(0xFF071E3E);
const _brandGold = Color(0xFFFFB500);

ThemeData _barkBeaconTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: _brandOrange,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFFFB68F) : const Color(0xFFA63800),
        onPrimary: dark ? const Color(0xFF4D1800) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF51250F)
            : const Color(0xFFFFE5D6),
        onPrimaryContainer: dark
            ? const Color(0xFFFFDAC5)
            : const Color(0xFF652400),
        surface: dark ? const Color(0xFF101E32) : Colors.white,
        onSurface: dark ? const Color(0xFFF1F5FC) : _brandNavy,
        onSurfaceVariant: dark
            ? const Color(0xFFB6C4D8)
            : const Color(0xFF465772),
        outlineVariant: dark
            ? const Color(0xFF34455D)
            : const Color(0xFFE7DED5),
      );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );
  return base.copyWith(
    scaffoldBackgroundColor: dark
        ? const Color(0xFF091426)
        : const Color(0xFFFFF8F2),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.all(18),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: shape,
      ),
    ),
  );
}

class BarkBeaconApp extends StatefulWidget {
  const BarkBeaconApp({super.key});

  @override
  State<BarkBeaconApp> createState() => _BarkBeaconAppState();
}

class _BarkBeaconAppState extends State<BarkBeaconApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late final _lightTheme = _barkBeaconTheme(Brightness.light);
  late final _darkTheme = _barkBeaconTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BarkBeacon',
    debugShowCheckedModeBanner: false,
    theme: _lightTheme,
    darkTheme: _darkTheme,
    themeMode: _themeMode,
    home: MainPage(onThemeChanged: (mode) => setState(() => _themeMode = mode)),
  );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.onThemeChanged});

  final ValueChanged<ThemeMode>? onThemeChanged;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ColorScheme get colors => Theme.of(context).colorScheme;

  int page = 0;
  bool mapOpened = false;
  bool saving = false;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final breed = TextEditingController();
  final details = TextEditingController();

  String savedName = '';
  String savedBreed = '';
  String savedDetails = '';

  @override
  void initState() {
    super.initState();
    loadHomePet();
  }

  Future<void> loadHomePet() async {
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) return;

      final result = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (!mounted || result.docs.isEmpty || savedName.isNotEmpty) return;

      final pet = result.docs.first.data();

      setState(() {
        savedName = pet['name'] as String? ?? '';
        savedBreed = pet['breed'] as String? ?? '';
        savedDetails = pet['details'] as String? ?? '';
      });
    } on FirebaseException catch (error) {
      debugPrint('Could not load Home pet: ${error.code}');
    }
  }

  @override
  void dispose() {
    name.dispose();
    breed.dispose();
    details.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final petName = name.text.trim();
    final petBreed = breed.text.trim();
    final petDetails = details.text.trim();

    setState(() => saving = true);

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      if (user == null) {
        throw StateError('Firebase sign-in did not return a user.');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .add({
            'name': petName,
            'breed': petBreed,
            'details': petDetails,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      setState(() {
        savedName = petName;
        savedBreed = petBreed;
        savedDetails = petDetails;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Saved.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colors.primary,
          ),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not save: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colors.error,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.outlineVariant),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14071E3E),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );

  Widget badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: _brandGold,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _brandNavy,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );

  Widget dogAvatar({double size = 88}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(size * .32),
      border: Border.all(color: colors.surface, width: 4),
    ),
    child: Icon(Icons.pets_rounded, color: colors.primary, size: size * .46),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Image.asset(
            'assets/images/barkbeacon_icon.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: 'Bark',
                children: [
                  TextSpan(
                    text: 'Beacon',
                    style: TextStyle(color: colors.primary),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: Theme.of(context).brightness == Brightness.dark
              ? 'Switch to light mode'
              : 'Switch to dark mode',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: widget.onThemeChanged == null
              ? null
              : () {
                  widget.onThemeChanged!(
                    Theme.of(context).brightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
                },
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: IndexedStack(
            index: page,
            children: [
              home(),
              profile(),
              if (page == 2)
                const MissingPetsPage()
              else
                const SizedBox.shrink(),
              if (mapOpened) const PetMapPage() else const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: page == 0
        ? FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyPetsPage()),
              );
            },
            icon: const Icon(Icons.pets),
            label: const Text('My Pets'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: page,
      onDestinationSelected: (value) {
        setState(() {
          page = value;
          if (value == 3) mapOpened = true;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search),
          label: 'Missing Pets',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Map',
        ),
      ],
    ),
  );

  Widget home() => ListView(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 88),
    children: [
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_brandNavy, Color(0xFF183759)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30071E3E),
              blurRadius: 25,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -25,
              top: 12,
              child: Icon(
                Icons.pets_rounded,
                size: 185,
                color: Color(0x18FFFFFF),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge('EVERY DOG HAS A HOME'),
                  const SizedBox(height: 22),
                  const Text(
                    'Let’s help them\nfind their way.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'A familiar face. A helpful neighbour.\n'
                    'A better chance of getting home.',
                    style: TextStyle(color: Color(0xFFE3EDFF), height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandOrange,
                      foregroundColor: _brandNavy,
                    ),
                    onPressed: () => setState(() => page = 1),
                    icon: Icon(
                      savedName.isEmpty
                          ? Icons.add_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      savedName.isEmpty
                          ? 'Add my dog'
                          : 'View my dog’s profile',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Your best friend',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => page = 1),
            child: Text(savedName.isEmpty ? 'Add profile' : 'Edit profile'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                dogAvatar(size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savedName.isEmpty ? 'Meet your dog here' : savedName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        savedName.isEmpty
                            ? 'Create their first profile'
                            : savedBreed.isEmpty
                            ? 'Your four-legged friend'
                            : savedBreed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              savedName.isEmpty
                  ? 'Keep their name, breed and unique markings together.'
                  : savedDetails.isEmpty
                  ? 'Add distinctive markings to make recognition easier.'
                  : savedDetails,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.outlineVariant),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => setState(() => page = 1),
                icon: const Icon(Icons.pets_outlined),
                label: Text(
                  savedName.isEmpty ? 'Create dog profile' : 'Open dog profile',
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 21),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'A clear photo and distinctive markings help people '
                'recognise your dog.',
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget profile() => ListView(
    padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
    children: [
      Row(
        children: [
          IconButton(
            onPressed: () => setState(() => page = 0),
            tooltip: 'Back to Home',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          const Text(
            'My dog profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_brandNavy, Color(0xFF183759)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            dogAvatar(size: 98),
            const SizedBox(height: 14),
            Text(
              savedName.isEmpty ? 'Their story starts here.' : savedName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Small details. A familiar face.',
              style: TextStyle(color: Color(0xFFE0EAFF)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      panel(
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The essentials',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Help your community recognise your dog.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                enabled: !saving,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Dog’s name *',
                  hintText: 'e.g. Buddy',
                  prefixIcon: Icon(Icons.pets_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your dog’s name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: breed,
                enabled: !saving,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Breed (optional)',
                  hintText: 'e.g. Golden retriever',
                  prefixIcon: Icon(Icons.info_outline_rounded),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: details,
                enabled: !saving,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Identifying details (optional)',
                  hintText: 'Coat colour, collar and unique markings…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  saving ? 'Saving...' : 'Save dog profile',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Save your dog's details",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

//sharaf

//rashmika

