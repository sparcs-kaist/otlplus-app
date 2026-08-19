import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:provider/provider.dart';

const _DAYS_KO = ['월', '화', '수', '목', '금'];
const _DAYS_EN = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

class AddCustomBlockDialog extends StatefulWidget {
  const AddCustomBlockDialog({Key? key}) : super(key: key);

  @override
  State<AddCustomBlockDialog> createState() => _AddCustomBlockDialogState();
}

class _AddCustomBlockDialogState extends State<AddCustomBlockDialog> {
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  int _selectedDay = 0;
  int _beginHour = 9;
  int _beginMin = 0;
  int _endHour = 10;
  int _endMin = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.locale == Locale('ko');
    final days = isKo ? _DAYS_KO : _DAYS_EN;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OTLColor.grayF,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: OTLColor.gray0.withValues(alpha: .15),
                offset: const Offset(2, 2),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '커스텀 블록 추가' : 'Add Custom Block',
                style: titleBold,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isKo ? '블록 이름' : 'Block Name',
                  labelStyle: bodyRegular.copyWith(color: OTLColor.gray75),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: bodyRegular,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _placeController,
                decoration: InputDecoration(
                  labelText: isKo ? '장소' : 'Place',
                  labelStyle: bodyRegular.copyWith(color: OTLColor.gray75),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: bodyRegular,
              ),
              const SizedBox(height: 12),
              Text(isKo ? '요일' : 'Day', style: labelBold),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: List.generate(5, (i) {
                  final selected = _selectedDay == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: Container(
                      width: 40,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? OTLColor.pinksMain : OTLColor.grayE,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        days[i],
                        style: labelBold.copyWith(
                          color: selected ? OTLColor.grayF : OTLColor.gray3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(isKo ? '시작 시간' : 'Start Time', style: labelBold),
              const SizedBox(height: 6),
              _buildTimePicker(
                hour: _beginHour,
                minute: _beginMin,
                onHourChanged: (h) => setState(() => _beginHour = h),
                onMinChanged: (m) => setState(() => _beginMin = m),
              ),
              const SizedBox(height: 12),
              Text(isKo ? '종료 시간' : 'End Time', style: labelBold),
              const SizedBox(height: 6),
              _buildTimePicker(
                hour: _endHour,
                minute: _endMin,
                onHourChanged: (h) => setState(() => _endHour = h),
                onMinChanged: (m) => setState(() => _endMin = m),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackgroundButton(
                        color: OTLColor.grayE,
                        onTap: () => OTLNavigator.pop(context),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            'common.cancel'.tr(),
                            style: bodyBold.copyWith(color: OTLColor.gray0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackgroundButton(
                        color: OTLColor.pinksMain,
                        onTap: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) return;

                          final begin = _beginHour * 60 + _beginMin;
                          final end = _endHour * 60 + _endMin;
                          if (end <= begin) return;

                          context.read<TimetableModel>().addCustomBlock(
                                blockName: name,
                                place: _placeController.text.trim(),
                                day: _selectedDay,
                                begin: begin,
                                end: end,
                              );
                          OTLNavigator.pop(context);
                        },
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            'common.add'.tr(),
                            style: bodyBold.copyWith(color: OTLColor.grayF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required int hour,
    required int minute,
    required ValueChanged<int> onHourChanged,
    required ValueChanged<int> onMinChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: OTLColor.grayD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: hour,
                isExpanded: true,
                style: bodyRegular.copyWith(color: OTLColor.gray0),
                items: List.generate(15, (i) => i + 8).map((h) {
                  return DropdownMenuItem(
                    value: h,
                    child: Text('${h.toString().padLeft(2, '0')}'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onHourChanged(v);
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(':', style: titleBold),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: OTLColor.grayD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: minute,
                isExpanded: true,
                style: bodyRegular.copyWith(color: OTLColor.gray0),
                items: [0, 15, 30, 45].map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text('${m.toString().padLeft(2, '0')}'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onMinChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DeleteCustomBlockDialog extends StatelessWidget {
  final CustomBlock block;

  const DeleteCustomBlockDialog({Key? key, required this.block})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isKo = context.locale == Locale('ko');

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 256,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OTLColor.grayF,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: OTLColor.gray0.withValues(alpha: .15),
                offset: const Offset(2, 2),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 48, color: OTLColor.pinksMain),
              const SizedBox(height: 16),
              Text(
                isKo ? '커스텀 블록 삭제' : 'Delete Custom Block',
                style: titleBold,
              ),
              const SizedBox(height: 8),
              Text(
                isKo
                    ? "'${block.blockName}' 블록을 삭제하시겠습니까?"
                    : "Do you want to delete '${block.blockName}'?",
                style: bodyRegular,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackgroundButton(
                        color: OTLColor.grayE,
                        onTap: () => OTLNavigator.pop(context),
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          child: Text(
                            'common.cancel'.tr(),
                            style: bodyBold.copyWith(color: OTLColor.gray0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackgroundButton(
                        color: OTLColor.pinksMain,
                        onTap: () {
                          context
                              .read<TimetableModel>()
                              .removeCustomBlock(block: block);
                          OTLNavigator.pop(context);
                        },
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          child: Text(
                            'common.delete'.tr(),
                            style: bodyBold.copyWith(color: OTLColor.grayF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
