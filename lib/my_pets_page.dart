import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  late Future<User> _user;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _user = _signIn();
  }

  Future<User> _signIn() async {
    final auth = FirebaseAuth.instance;
    final existingUser = auth.currentUser;

    if (existingUser != null) {
      return existingUser;
    }

    final result = await auth.signInAnonymously();
    return result.user!;
  }

  Future<void> _saveChange(
    Future<void> Function() change,
    String successMessage,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await change();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save change (${error.code}).')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editPet(
    CollectionReference<Map<String, dynamic>> pets, {
    QueryDocumentSnapshot<Map<String, dynamic>>? pet,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _PetNameDialog(
        initialName: pet?.data()['name'] as String?,
      ),
    );

    if (!mounted || name == null) return;

    await _saveChange(() async {
      if (pet == null) {
        await pets.add({'name': name});
      } else {
        await pet.reference.update({'name': name});
      }
    }, pet == null ? 'Pet added.' : 'Pet renamed.');
  }

  Future<void> _deletePet(
    QueryDocumentSnapshot<Map<String, dynamic>> pet,
  ) async {
    final name = pet.data()['name'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('This will remove the pet from My Pets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    await _saveChange(pet.reference.delete, 'Pet deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _user,
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Pets')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sign-in failed: ${authSnapshot.error}'),
                  TextButton(
                    onPressed: () => setState(() => _user = _signIn()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pets = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('pets');

        return Scaffold(
          appBar: AppBar(title: const Text('My Pets')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _saving ? null : () => _editPet(pets),
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
          ),
          body: Column(
            children: [
              if (_saving) const LinearProgressIndicator(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: pets.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final error = snapshot.error;
                      final detail = error is FirebaseException
                          ? ' (${error.code})'
                          : '';
                      return Center(
                        child: Text('Could not load pets$detail.'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final documents = snapshot.data!.docs;
                    if (documents.isEmpty) {
                      return const Center(child: Text('Add your first pet.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final pet = documents[index];
                        return ListTile(
                          leading: const Icon(Icons.pets),
                          title: Text(pet.data()['name'] as String),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Rename pet',
                                onPressed: _saving
                                    ? null
                                    : () => _editPet(pets, pet: pet),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete pet',
                                onPressed: _saving
                                    ? null
                                    : () => _deletePet(pet),
                                icon: const Icon(Icons.delete_outline),
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
          ),
        );
      },
    );
  }
}

class _PetNameDialog extends StatefulWidget {
  const _PetNameDialog({this.initialName});

  final String? initialName;

  @override
  State<_PetNameDialog> createState() => _PetNameDialogState();
}

class _PetNameDialogState extends State<_PetNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Add Pet' : 'Rename Pet'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Pet name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter your pet’s name.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}