import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

CollectionReference<Map<String, dynamic>> get _reports =>
    FirebaseFirestore.instance.collection('missingReports');

Future<User> _signedInUser() async {
  final auth = FirebaseAuth.instance;
  final user =
      await auth.authStateChanges().first ??
      (await auth.signInAnonymously()).user;
  if (user == null) throw StateError('Could not sign in.');
  return user;
}

class MissingPetsPage extends StatefulWidget {
  const MissingPetsPage({super.key});

  @override
  State<MissingPetsPage> createState() => _MissingPetsPageState();
}

class _MissingPetsPageState extends State<MissingPetsPage> {
  late Future<User> session;
  late Stream<QuerySnapshot<Map<String, dynamic>>> reports;

  @override
  void initState() {
    super.initState();
    connect();
  }

  void connect() {
    session = _signedInUser();
    reports = _reports.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> openForm({String? reportId, String? petName}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ReportForm(reportId: reportId, petName: petName),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reportId == null ? 'Missing pet reported.' : 'Sighting submitted.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: session,
      builder: (context, auth) {
        if (auth.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(connect),
              child: const Text('Could not sign in. Retry'),
            ),
          );
        }
        if (!auth.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                onPressed: () => openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Report a missing pet'),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: reports,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed: () => setState(connect),
                        child: const Text('Could not load reports. Retry'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No missing pets reported yet.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final report = docs[index];
                      final data = report.data();
                      final petName = data['petName'] as String;
                      final photo = data['photo'] as Blob;
                      return Card(
                        key: ValueKey(report.id),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.memory(
                              photo.bytes,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(
                                height: 100,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                            ListTile(
                              title: Text(petName),
                              subtitle: Text(
                                "Last seen near ${data['location']}\n${data['description']}",
                              ),
                            ),
                            if (data['ownerId'] == auth.data!.uid)
                              ExpansionTile(
                                title: const Text('View sightings'),
                                children: [
                                  _SightingsList(report: report.reference),
                                ],
                              )
                            else
                              TextButton(
                                onPressed: () => openForm(
                                  reportId: report.id,
                                  petName: petName,
                                ),
                                child: const Text('Submit a sighting'),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SightingsList extends StatefulWidget {
  const _SightingsList({required this.report});

  final DocumentReference<Map<String, dynamic>> report;

  @override
  State<_SightingsList> createState() => _SightingsListState();
}

class _SightingsListState extends State<_SightingsList> {
  late final sightings = widget.report
      .collection('sightings')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: sightings,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ListTile(title: Text('Could not load sightings.'));
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const ListTile(title: Text('No sightings yet.'));
        }
        return Column(
          children: [
            for (final doc in docs)
              ListTile(
                title: Text(doc.data()['location'] as String),
                subtitle: Text(doc.data()['description'] as String),
              ),
          ],
        );
      },
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({this.reportId, this.petName});

  final String? reportId;
  final String? petName;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();
  final picker = ImagePicker();
  Blob? photo;
  String? error;
  bool busy = false;

  bool get isSighting => widget.reportId != null;

  @override
  void dispose() {
    name.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 500000) {
        if (mounted) setState(() => error = 'Choose a photo under 500 KB.');
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      if (mounted) setState(() => photo = Blob(bytes));
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not open that photo. Try another one.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (!isSighting && photo == null) {
      setState(() => error = 'Choose a photo of your pet.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    final fields = <String, dynamic>{
      'location': location.text.trim(),
      'description': description.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      final user = await _signedInUser();
      final reportId = widget.reportId;
      if (reportId == null) {
        await _reports.add({
          ...fields,
          'ownerId': user.uid,
          'petName': name.text.trim(),
          'photo': photo!,
        });
      } else {
        await _reports.doc(reportId).collection('sightings').add({
          ...fields,
          'reporterId': user.uid,
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseException catch (failure) {
      if (mounted) {
        setState(
          () => error = failure.code == 'permission-denied'
              ? 'Firebase denied access. Check the Firestore rules.'
              : 'Could not submit. Check your connection and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not submit. Please try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label,
    int limit, {
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      enabled: !busy,
      maxLength: limit,
      maxLines: lines,
      validator: (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSighting ? 'Submit a sighting' : 'Report a missing pet'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isSighting) Text('Sighting for ${widget.petName}'),
                if (!isSighting) field(name, 'Pet name', 80),
                field(
                  location,
                  isSighting ? 'Sighting location' : 'Last-seen location',
                  200,
                ),
                field(
                  description,
                  isSighting ? 'What did you see?' : 'Pet description',
                  1000,
                  lines: 4,
                ),
                if (!isSighting) ...[
                  if (photo != null) Image.memory(photo!.bytes, height: 160),
                  OutlinedButton.icon(
                    onPressed: busy ? null : pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      photo == null ? 'Choose pet photo' : 'Change photo',
                    ),
                  ),
                ],
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: const Text('Submit'),
                ),
                if (busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
