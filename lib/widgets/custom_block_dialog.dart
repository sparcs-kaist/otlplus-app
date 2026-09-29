import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/providers/timetable_model.dart';

Future<void> showCustomBlockEditor(
  BuildContext context,
  TimetableModel model, {
  CustomBlock? block,
}) async {
  final timetableId = model.currentTimetable.id;
  await showDialog<void>(
    context: context,
    builder: (_) =>
        CustomBlockDialog(model: model, timetableId: timetableId, block: block),
  );
}

class CustomBlockDialog extends StatefulWidget {
  const CustomBlockDialog({
    super.key,
    required this.model,
    required this.timetableId,
    this.block,
  });
  final TimetableModel model;
  final int timetableId;
  final CustomBlock? block;
  @override
  State<CustomBlockDialog> createState() => _CustomBlockDialogState();
}

class _CustomBlockDialogState extends State<CustomBlockDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.block?.name ?? '');
  late final _place = TextEditingController(text: widget.block?.place ?? '');
  late final _begin = TextEditingController(
    text: _format(widget.block?.begin ?? 540),
  );
  late final _end = TextEditingController(
    text: _format(widget.block?.end ?? 600),
  );
  late int _day = widget.block?.day ?? 0;
  bool _busy = false;
  String? _error;
  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  static String _format(int time) =>
      '${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')}';
  int? _parse(String text) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
    if (match == null) return null;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 24 || minute > 59 || (hour == 24 && minute != 0)) return null;
    return hour * 60 + minute;
  }

  @override
  void dispose() {
    for (final controller in [_name, _place, _begin, _end])
      controller.dispose();
    super.dispose();
  }

  Future<void> _submit({bool delete = false}) async {
    if (_busy) return;
    if (!delete && !_form.currentState!.validate()) return;
    if (delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text('custom_block.confirm_delete'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('common.delete'.tr()),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    final block = CustomBlock(
      id: widget.block?.id ?? 0,
      name: _name.text.trim(),
      place: _place.text.trim(),
      day: _day,
      begin: _parse(_begin.text) ?? 0,
      end: _parse(_end.text) ?? 0,
    );
    if (!delete &&
        widget.model.currentTimetable.customBlocks.any(
          (other) => other.id != block.id && other.overlaps(block),
        )) {
      setState(() => _error = 'custom_block.overlap'.tr());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final saved = delete
        ? await widget.model.deleteCustomBlock(
            widget.timetableId,
            widget.block!.id,
          )
        : await widget.model.saveCustomBlock(widget.timetableId, block);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = 'custom_block.failed'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        (widget.block == null ? 'custom_block.add' : 'custom_block.edit').tr(),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'custom_block.name'.tr(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'custom_block.required'.tr()
                    : null,
              ),
              TextFormField(
                controller: _place,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'custom_block.place'.tr(),
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: InputDecoration(labelText: 'custom_block.day'.tr()),
                items: List.generate(
                  7,
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text('timetable.days.${_days[day]}'.tr()),
                  ),
                ),
                onChanged: _busy ? null : (day) => setState(() => _day = day!),
              ),
              TextFormField(
                controller: _begin,
                enabled: !_busy,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'custom_block.begin'.tr(),
                  hintText: '09:00',
                ),
                validator: (value) =>
                    _parse(value ?? '') == null || _parse(value!)! >= 1440
                    ? 'custom_block.invalid_time'.tr()
                    : null,
              ),
              TextFormField(
                controller: _end,
                enabled: !_busy,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'custom_block.end'.tr(),
                  hintText: '10:00',
                ),
                validator: (value) =>
                    _parse(value ?? '') == null ||
                        _parse(value!)! <= (_parse(_begin.text) ?? 1440)
                    ? 'custom_block.invalid_time'.tr()
                    : null,
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.block != null)
          TextButton(
            onPressed: _busy ? null : () => _submit(delete: true),
            child: Text('common.delete'.tr()),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: Text('custom_block.save'.tr()),
        ),
      ],
    ),
  );
}
