import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../cubits/assistant_cubit.dart';

@RoutePage()
class AssistantFormScreen extends StatefulWidget {
  final Map<String, dynamic>? assistant;

  const AssistantFormScreen({super.key, this.assistant});

  @override
  State<AssistantFormScreen> createState() => _AssistantFormScreenState();
}

class _AssistantFormScreenState extends State<AssistantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _serialCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.assistant?['name'] as String? ?? '',
    );
    _serialCtrl = TextEditingController(
      text: widget.assistant?['serial_number'] as String? ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.assistant?['phone'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameCtrl.text.trim(),
        'serial_number': _serialCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      if (widget.assistant == null) {
        context.read<AssistantCubit>().createAssistant(data);
      } else {
        context.read<AssistantCubit>().updateAssistant(
          widget.assistant!['id'] as int,
          data,
        );
      }
      context.router.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.assistant != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? LocaleKeys.edit_assistant.tr()
              : LocaleKeys.add_assistant.tr(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: LocaleKeys.name.tr(),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? LocaleKeys.required_field.tr()
                    : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _serialCtrl,
                decoration: InputDecoration(
                  labelText: LocaleKeys.assistant_serial_number.tr(),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? LocaleKeys.required_field.tr()
                    : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: LocaleKeys.phone_number.tr(),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(LocaleKeys.save.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
