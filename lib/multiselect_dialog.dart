import 'package:flutter/material.dart';

const EdgeInsets _defaultInsetPadding =
    EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);

class MultiSelectDialogItem<V> {
  const MultiSelectDialogItem({required this.value, required this.label});

  final V value;
  final String label;
}

class MultiSelectDialog<V> extends StatefulWidget {
  const MultiSelectDialog(
      {Key? key,
      this.title,
      this.titlePadding,
      this.titleTextStyle,
      this.contentPadding = const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
      this.contentTextStyle,
      this.actionsPadding = EdgeInsets.zero,
      this.actionsOverflowDirection,
      this.actionsOverflowButtonSpacing,
      this.buttonPadding,
      this.backgroundColor,
      this.elevation,
      this.semanticLabel,
      this.insetPadding = _defaultInsetPadding,
      this.clipBehavior = Clip.none,
      this.shape,
      this.items,
      this.initialSelectedValues})
      : super(key: key);

  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleTextStyle;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? contentTextStyle;
  final EdgeInsetsGeometry actionsPadding;
  final VerticalDirection? actionsOverflowDirection;
  final double? actionsOverflowButtonSpacing;
  final EdgeInsetsGeometry? buttonPadding;
  final Color? backgroundColor;
  final double? elevation;
  final String? semanticLabel;
  final EdgeInsets insetPadding;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final List<MultiSelectDialogItem<V>>? items;
  final Set<V>? initialSelectedValues;

  @override
  State<StatefulWidget> createState() => _MultiSelectDialogState<V>();
}

class _MultiSelectDialogState<V> extends State<MultiSelectDialog<V>> {
  final _selectedValues = <V>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedValues != null) {
      _selectedValues.addAll(widget.initialSelectedValues!);
    }
  }

  void _onItemCheckedChange(V itemValue, bool checked) {
    setState(() {
      if (checked) {
        _selectedValues.add(itemValue);
      } else {
        _selectedValues.remove(itemValue);
      }
    });
  }

  void _onCancelTap() {
    Navigator.pop(context);
  }

  void _onSubmitTap() {
    Navigator.pop(context, _selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: SingleChildScrollView(
        child: ListTileTheme(
          contentPadding: const EdgeInsets.fromLTRB(14.0, 0.0, 24.0, 0.0),
          child: ListBody(
            children: widget.items?.map(_buildItem).toList() ?? <Widget>[],
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: _onCancelTap,
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _onSubmitTap,
          child: const Text('OK'),
        )
      ],
      titlePadding: widget.titlePadding,
      titleTextStyle: widget.titleTextStyle,
      contentPadding: widget.contentPadding,
      contentTextStyle: widget.contentTextStyle,
      actionsPadding: widget.actionsPadding,
      actionsOverflowDirection: widget.actionsOverflowDirection,
      actionsOverflowButtonSpacing: widget.actionsOverflowButtonSpacing,
      buttonPadding: widget.buttonPadding,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      semanticLabel: widget.semanticLabel,
      insetPadding: widget.insetPadding,
      clipBehavior: widget.clipBehavior,
      shape: widget.shape,
    );
  }

  Widget _buildItem(MultiSelectDialogItem<V> item) {
    final checked = _selectedValues.contains(item.value);
    return CheckboxListTile(
      value: checked,
      title: Text(item.label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (checked) =>
          checked != null ? _onItemCheckedChange(item.value, checked) : null,
    );
  }
}
