import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/providers/timetable_model.dart';

Future<void> showCustomBlockEditor(
  BuildContext context,
  TimetableModel model, {
  CustomBlock? block,
}) async {
  if (!model.isLoaded || model.isMyTimetable) return;
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
  late final List<_TimeInput> _times =
      (widget.block?.occurrences ??
              [const CustomBlockTime(day: 0, begin: 540, end: 600)])
          .map(_TimeInput.new)
          .toList();
  bool _busy = false;
  String? _error;
  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

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
    for (final controller in [_name, _place]) controller.dispose();
    for (final time in _times) {
      time.dispose();
    }
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
    final times = _times
        .map(
          (time) => CustomBlockTime(
            day: time.day,
            begin: _parse(time.begin.text) ?? 0,
            end: _parse(time.end.text) ?? 0,
          ),
        )
        .toList();
    final block = CustomBlock(
      id: widget.block?.id ?? 0,
      name: _name.text.trim(),
      place: _place.text.trim(),
      day: times.first.day,
      begin: times.first.begin,
      end: times.first.end,
      times: times,
    );
    if (!delete &&
        (block.hasInternalOverlap ||
            widget.model.currentTimetable.customBlocks.any(
              (other) => other.id != block.id && other.overlaps(block),
            ))) {
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
              for (final time in _times) ...[
                DropdownButtonFormField<int>(
                  key: ObjectKey(time),
                  initialValue: time.day,
                  decoration: InputDecoration(
                    labelText: 'custom_block.day'.tr(),
                  ),
                  items: List.generate(
                    7,
                    (day) => DropdownMenuItem(
                      value: day,
                      child: Text('timetable.days.${_days[day]}'.tr()),
                    ),
                  ),
                  onChanged: _busy
                      ? null
                      : (day) => setState(() => time.day = day!),
                ),
                TextFormField(
                  controller: time.begin,
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
                  controller: time.end,
                  enabled: !_busy,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: 'custom_block.end'.tr(),
                    hintText: '10:00',
                  ),
                  validator: (value) =>
                      _parse(value ?? '') == null ||
                          _parse(value!)! <= (_parse(time.begin.text) ?? 1440)
                      ? 'custom_block.invalid_time'.tr()
                      : null,
                ),
                if (_times.length > 1)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _times.remove(time);
                            time.dispose();
                          }),
                    child: Text('custom_block.remove_time'.tr()),
                  ),
              ],
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(
                        () => _times.add(
                          _TimeInput(
                            const CustomBlockTime(day: 0, begin: 540, end: 600),
                          ),
                        ),
                      ),
                icon: const Icon(Icons.add),
                label: Text('custom_block.add_time'.tr()),
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

class _TimeInput {
  _TimeInput(CustomBlockTime time)
    : day = time.day,
      begin = TextEditingController(text: _format(time.begin)),
      end = TextEditingController(text: _format(time.end));
  int day;
  final TextEditingController begin;
  final TextEditingController end;
  static String _format(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  void dispose() {
    begin.dispose();
    end.dispose();
  }
}
