import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class IntakeFormScreen extends StatefulWidget {
  const IntakeFormScreen({super.key});

  @override
  State<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends State<IntakeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  double _painLevel = 5.0;
  String _triageLevel = 'Routine';
  final List<String> _languages = ['English', 'isiZulu', 'isiXhosa', 'Afrikaans'];
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Healthcare Intake Form',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: AppColors.surface,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: AppColors.primary),
            items: _languages.map((String lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(lang, style: const TextStyle(color: AppColors.textPrimary)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLanguage = val);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInputField('ID Number / Passport', 'Enter 13-digit ID', TextInputType.number),
              const SizedBox(height: 16),
              _buildInputField('Current Symptoms', 'E.g., Fever, coughing, chest pain', TextInputType.text, maxLines: 3),
              const SizedBox(height: 24),
              _buildPainSlider(),
              const SizedBox(height: 24),
              _buildTriageDropdown(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_services, size: 40, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instant Check-In', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Fill this out to generate your virtual patient card and get your queue number.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String placeholder, TextInputType type, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.white24),
            fillColor: AppColors.surface,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  Widget _buildPainSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pain Severity Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${_painLevel.round()} / 10', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _painLevel,
          min: 1.0,
          max: 10.0,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.cardBg,
          onChanged: (val) => setState(() => _painLevel = val),
        ),
      ],
    );
  }

  Widget _buildTriageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estimated Urgency (Self-Triage)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _triageLevel,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              isExpanded: true,
              items: <String>['Routine', 'Urgent', 'Critical'].map((String level) {
                Color badgeColor = AppColors.routine;
                if (level == 'Urgent') badgeColor = AppColors.urgent;
                if (level == 'Critical') badgeColor = AppColors.critical;
                return DropdownMenuItem<String>(
                  value: level,
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Text(level, style: const TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _triageLevel = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Submit form to FastAPI backend
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Submitting Intake Form...')),
            );
            Navigator.of(context).pop();
          }
        },
        child: const Text('Submit & Get Queue Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
