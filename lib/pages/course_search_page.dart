import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/search_filter_panel.dart';
import 'package:otlplus/widgets/search_textfield.dart';
import 'package:provider/provider.dart';

class CourseSearchPage extends StatefulWidget {
  final bool openKeyboard;
  const CourseSearchPage({Key? key, this.openKeyboard = true})
    : super(key: key);

  @override
  State<CourseSearchPage> createState() => _CourseSearchPageState();
}

class _CourseSearchPageState extends State<CourseSearchPage> {
  final _searchTextController = TextEditingController();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchTextController.text = context.read<CourseSearchModel>().searchText;
    _searchTextController.addListener(() {
      context.read<CourseSearchModel>().setSearchText(
        _searchTextController.text,
      );
    });
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OTLScaffold(
      resizeToAvoidBottomInset: true,
      child: OTLLayout(
        middle: Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: SearchTextfield(
            autoFocus: _searchTextController.text == '' && widget.openKeyboard,
            backgroundColor: OTLColor.grayF,
            textController: _searchTextController,
            focusNode: _focusNode,
          ),
        ),
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SearchFilterPanel(
                        filter: context.watch<CourseSearchModel>().courseFilter,
                        setFilter: context
                            .read<CourseSearchModel>()
                            .setCourseFilterSelected,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _searchTextController.clear();
                        context.read<CourseSearchModel>().resetCourseFilter();
                      },
                      child: Text(
                        "common.reset_all".tr(),
                        style: bodyBold.copyWith(color: OTLColor.pinksMain),
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(OTLColor.grayF),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        if (await context
                            .read<CourseSearchModel>()
                            .courseSearch()) {
                          OTLNavigator.pop(context, result: true);
                        } else {
                          _focusNode.requestFocus();
                        }
                      },
                      child: Text("common.search".tr(), style: bodyBold),
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
