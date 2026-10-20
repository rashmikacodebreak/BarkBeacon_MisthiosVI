import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BarkBeaconApp());
}

const blue = Color(0xFF2563EB);
const ink = Color(0xFF142447);
const muted = Color(0xFF687893);

class BarkBeaconApp extends StatelessWidget {
  const BarkBeaconApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BarkBeacon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          scaffoldBackgroundColor: const Color(0xFFF3F7FF),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w800),
            titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
            titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
            bodyMedium: TextStyle(color: muted, height: 1.5),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF5F8FF),
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFDFE8F8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFDFE8F8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: blue, width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        home: const MainPage(),
      );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int page = 0;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final breed = TextEditingController();
  final details = TextEditingController();
  String savedName = '';
  String savedBreed = '';
  String savedDetails = '';

  @override
  void dispose() {
    name.dispose();
    breed.dispose();
    details.dispose();
    super.dispose();
  }

  void save() {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      savedName = name.text.trim();
      savedBreed = breed.text.trim();
      savedDetails = details.text.trim();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Dog profile saved for this session.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: blue,
      ));
  }

  Widget panel(Widget child) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6EDFA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x082563EB),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );

  Widget badge(String text, {bool light = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: light ? const Color(0xFFDBEAFE) : const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF1749AE),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      );

  Widget dogAvatar({double size = 88}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3EFFF), Color(0xFFC4DCFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * .32),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Icon(Icons.pets_rounded, color: blue, size: size * .46),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: IndexedStack(
                index: page,
                children: [home(), profile()],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5EDFA))),
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: const Color(0xFFDBEAFE),
            selectedIndex: page,
            onDestinationSelected: (value) => setState(() => page = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: muted),
                selectedIcon: Icon(Icons.home_rounded, color: blue),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: muted),
                selectedIcon: Icon(Icons.person_rounded, color: blue),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );

  Widget home() => ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.pets_rounded, color: Colors.white),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BarkBeacon',
                      style: TextStyle(
                          color: ink, fontWeight: FontWeight.w800, fontSize: 21)),
                  Text('Together, closer to home.',
                      style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => page = 1),
              tooltip: 'Open profile',
              icon: const Icon(Icons.account_circle_outlined,
                  color: blue, size: 32),
            ),
          ]),
          const SizedBox(height: 28),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF123EA8), blue, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x302563EB),
                    blurRadius: 25,
                    offset: Offset(0, 12)),
              ],
            ),
            child: Stack(children: [
              const Positioned(
                right: -25,
                top: 12,
                child: Icon(Icons.pets_rounded,
                    size: 185, color: Color(0x18FFFFFF)),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge('EVERY DOG HAS A HOME', light: true),
                    const SizedBox(height: 22),
                    const Text('Let’s help them\nfind their way.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 33,
                            fontWeight: FontWeight.w800,
                            height: 1.15)),
                    const SizedBox(height: 14),
                    const Text(
                        'A familiar face. A helpful neighbour.\nA better chance of getting home.',
                        style: TextStyle(
                            color: Color(0xFFE3EDFF), height: 1.6)),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.white, foregroundColor: blue),
                      onPressed: () => setState(() => page = 1),
                      icon: Icon(savedName.isEmpty
                          ? Icons.add_rounded
                          : Icons.arrow_forward_rounded),
                      label: Text(savedName.isEmpty
                          ? 'Add my dog'
                          : 'View my dog’s profile'),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 30),
          Row(children: [
            const Expanded(
                child: Text('Your best friend',
                    style: TextStyle(
                        color: ink, fontSize: 21, fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: () => setState(() => page = 1),
              child: Text(savedName.isEmpty ? 'Add profile' : 'Edit profile'),
            ),
          ]),
          const SizedBox(height: 10),
          panel(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                dogAvatar(size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(savedName.isEmpty ? 'Meet your dog here' : savedName,
                          style: const TextStyle(
                              color: ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(savedName.isEmpty
                          ? 'Create their first profile'
                          : savedBreed.isEmpty
                              ? 'Your four-legged friend'
                              : savedBreed),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Text(savedName.isEmpty
                  ? 'Keep their name, breed and unique markings together.'
                  : savedDetails.isEmpty
                      ? 'Add distinctive markings to make recognition easier.'
                      : savedDetails),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blue,
                    side: const BorderSide(color: Color(0xFFC9DAFF)),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => page = 1),
                  icon: const Icon(Icons.pets_outlined),
                  label: Text(savedName.isEmpty
                      ? 'Create dog profile'
                      : 'Open dog profile'),
                ),
              ),
            ],
          )),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lightbulb_outline_rounded, color: blue, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'A clear photo and distinctive markings help people recognise your dog.'),
              ),
            ]),
          ),
        ],
      );

  Widget profile() => ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          Row(children: [
            IconButton(
              onPressed: () => setState(() => page = 0),
              tooltip: 'Back to Home',
              icon: const Icon(Icons.arrow_back_rounded, color: ink),
            ),
            const SizedBox(width: 4),
            const Text('My dog profile',
                style: TextStyle(
                    color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF123EA8), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(children: [
              dogAvatar(size: 98),
              const SizedBox(height: 14),
              Text(savedName.isEmpty ? 'Their story starts here.' : savedName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Small details. A familiar face.',
                  style: TextStyle(color: Color(0xFFE0EAFF))),
            ]),
          ),
          const SizedBox(height: 22),
          panel(Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('The essentials',
                    style: TextStyle(
                        color: ink, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Help your community recognise your dog.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dog’s name *',
                    hintText: 'e.g. Buddy',
                    prefixIcon: Icon(Icons.pets_rounded, color: blue),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your dog’s name.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: breed,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Breed (optional)',
                    hintText: 'e.g. Golden retriever',
                    prefixIcon: Icon(Icons.info_outline_rounded, color: blue),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: details,
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
                  onPressed: save,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Save dog profile',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                const Text('Saved for this demo session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          )),
        ],
      );
}
