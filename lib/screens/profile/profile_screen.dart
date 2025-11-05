import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../supabase/supabase_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String _signo = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final response = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      final googleName = user.userMetadata?['name'] ?? '';

      await SupabaseConfig.client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': googleName,
      });

      _nameController.text = googleName;
      _emailController.text = user.email ?? '';
    } else {
      _nameController.text = response['full_name'] ?? '';
      _emailController.text = response['email'] ?? user.email ?? '';
      if (response['birth_date'] != null) {
        final parsed = DateTime.parse(response['birth_date']);
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(parsed);
        _signo = _calcularSigno(parsed);
      }
    }
    setState(() {});
  }

  Future<void> _updateProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      DateTime? parsedDate;
      if (_birthDateController.text.isNotEmpty) {
        parsedDate =
            DateFormat('dd/MM/yyyy').parse(_birthDateController.text.trim());
        _signo = _calcularSigno(parsedDate);
      }

      await SupabaseConfig.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'birth_date': parsedDate?.toIso8601String(),
      }).eq('id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.updated'.tr())),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.error_update'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: context.locale,
    );
    if (pickedDate != null) {
      _birthDateController.text =
          DateFormat('dd/MM/yyyy').format(pickedDate);
      _signo = _calcularSigno(pickedDate);
      setState(() {});
    }
  }

  String _calcularSigno(DateTime data) {
    final dia = data.day;
    final mes = data.month;

    if ((mes == 3 && dia >= 21) || (mes == 4 && dia <= 19)) return 'Áries ♈';
    if ((mes == 4 && dia >= 20) || (mes == 5 && dia <= 20)) return 'Touro ♉';
    if ((mes == 5 && dia >= 21) || (mes == 6 && dia <= 20)) return 'Gêmeos ♊';
    if ((mes == 6 && dia >= 21) || (mes == 7 && dia <= 22)) return 'Câncer ♋';
    if ((mes == 7 && dia >= 23) || (mes == 8 && dia <= 22)) return 'Leão ♌';
    if ((mes == 8 && dia >= 23) || (mes == 9 && dia <= 22)) return 'Virgem ♍';
    if ((mes == 9 && dia >= 23) || (mes == 10 && dia <= 22)) return 'Libra ♎';
    if ((mes == 10 && dia >= 23) || (mes == 11 && dia <= 21)) return 'Escorpião ♏';
    if ((mes == 11 && dia >= 22) || (mes == 12 && dia <= 21)) return 'Sagitário ♐';
    if ((mes == 12 && dia >= 22) || (mes == 1 && dia <= 19)) return 'Capricórnio ♑';
    if ((mes == 1 && dia >= 20) || (mes == 2 && dia <= 18)) return 'Aquário ♒';
    if ((mes == 2 && dia >= 19) || (mes == 3 && dia <= 20)) return 'Peixes ♓';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFEDE7F6),
              child: Icon(Icons.person, size: 50, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 16),
            Text(
              _nameController.text.isEmpty
                  ? 'profile.no_name'.tr()
                  : _nameController.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (_signo.isNotEmpty)
              Text(
                'profile.sign'.tr(args: [_signo]),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              )
            else
              Text(
                'profile.add_birthdate'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'profile.full_name'.tr(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: InputDecoration(
                labelText: 'profile.birth_date'.tr(),
                prefixIcon: const Icon(Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'profile.email'.tr(),
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('profile.save_changes'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
