import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phraseController = TextEditingController();
  DateTime? _birthDate;
  String _photoUrl = '';
  bool _isPremium = false;
  String _language = 'pt';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = SupabaseConfig.getCurrentUser();
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _nameController.text = response['full_name'] ?? '';
        _phraseController.text = response['personal_phrase'] ?? '';
        _photoUrl = response['photo_url'] ?? '';
        _isPremium = response['is_premium'] ?? false;
        _language = response['language'] ?? 'pt';
        _birthDate = response['birth_date'] != null
            ? DateTime.tryParse(response['birth_date'])
            : null;
      });
    } catch (e) {
      print('❌ Erro ao carregar perfil: $e');
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = SupabaseConfig.getCurrentUser();
      if (user == null) return;

      await SupabaseConfig.client.from('profiles').update({
        'full_name': _nameController.text,
        'personal_phrase': _phraseController.text,
        'birth_date': _birthDate?.toIso8601String(),
        'photo_url': _photoUrl,
        'language': _language,
      }).eq('id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.success'.tr()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.error'.tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'profile.title'.tr(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildForm(),
            const SizedBox(height: 20),
            _buildLanguageSelector(),
            if (_isPremium) _buildPremiumBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                backgroundColor: Colors.grey[200],
                child: _photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _changeProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'profile.name'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _birthDate != null ? _getAgeAndSign(_birthDate!) : '',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'profile.name'.tr(),
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phraseController,
            label: 'profile.about_me'.tr(),
            icon: Icons.chat_bubble_outline,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.grey[50] : Colors.grey[100],
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _isEditing ? _pickBirthDate : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isEditing ? Colors.grey[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: Colors.pink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'profile.birth_date'.tr(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Idioma / Language',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          DropdownButton<String>(
            value: _language,
            items: const [
              DropdownMenuItem(value: 'pt', child: Text('Português')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: _isEditing
                ? (value) async {
              if (value != null) {
                setState(() => _language = value);
                await context.setLocale(Locale(value));
              }
            }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'profile.premium'.tr(),
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;
    final file = File(picked.path);
    final user = SupabaseConfig.getCurrentUser();
    if (user == null) return;

    try {
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await SupabaseConfig.client.storage
          .from('profile_photos')
          .upload(fileName, file);

      final publicUrl = SupabaseConfig.client.storage
          .from('profile_photos')
          .getPublicUrl(fileName);

      await SupabaseConfig.client
          .from('profiles')
          .update({'photo_url': publicUrl})
          .eq('id', user.id);

      setState(() => _photoUrl = publicUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto atualizada com sucesso!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erro ao enviar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao enviar imagem'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getAgeAndSign(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    final sign = _getZodiacSign(birthDate);
    return '$age anos • $sign';
  }

  String _getZodiacSign(DateTime date) {
    final month = date.month;
    final day = date.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Áries ♈';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Touro ♉';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gêmeos ♊';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Câncer ♋';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leão ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgem ♍';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra ♎';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Escorpião ♏';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagitário ♐';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricórnio ♑';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquário ♒';
    return 'Peixes ♓';
  }
}
