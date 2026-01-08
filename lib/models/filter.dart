class FilterGroupInfo {
  final String label;
  final String type;
  final bool isMultiSelect;
  final List<List<CodeLabelPair>> options;
  FilterGroupInfo({
    required this.label,
    this.type = "radio",
    this.isMultiSelect = true,
    this.options = const [[]],
  });
}

class CodeLabelPair {
  final String code;
  final String label;
  bool selected;
  CodeLabelPair({required this.code, this.label = "", this.selected = false});
}
