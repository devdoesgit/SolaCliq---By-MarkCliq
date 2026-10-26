import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

/// An uppercase label, a row of [SolaChips], and the group's error.
class ChipGroup<T> extends StatelessWidget {
  const new({
    required ValueKey<String> super.key,
    required this.label,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.error,
  });

  final String label;
  final List<SolaChoice<T>> choices;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space10,
      children: [
        SolaSectionLabel(label),
        SolaChips<T>(
          key: key! as ValueKey<String>,
          label: label,
          choices: choices,
          selected: selected,
          onChanged: onChanged,
        ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: SolaText(
              error,
              style: SolaTextStyle.meta,
              color: SolaColors.danger,
            ),
          ),
      ],
    );
  }
}
