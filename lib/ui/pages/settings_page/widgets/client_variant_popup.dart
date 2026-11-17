import 'package:material_ui/material_ui.dart';

import '../../../../kugou_api.dart';

String kugouClientVariantLabel(KugouClientVariant variant) => switch (variant) {
  KugouClientVariant.lite => '概念版',
  KugouClientVariant.standard => '标准版',
};

final class ClientVariantPopup extends StatelessWidget {
  const ClientVariantPopup({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final KugouClientVariant selected;
  final ValueChanged<KugouClientVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = kugouClientVariantLabel(selected);
    return PopupMenuButton<KugouClientVariant>(
      key: const ValueKey<String>('kugou-client-variant-popup'),
      tooltip: '选择音源客户端',
      initialValue: selected,
      position: PopupMenuPosition.under,
      borderRadius: BorderRadius.circular(20),
      splashRadius: 20,
      onSelected: onSelected,
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      itemBuilder: (context) =>
          const <KugouClientVariant>[
                KugouClientVariant.lite,
                KugouClientVariant.standard,
              ]
              .map<PopupMenuEntry<KugouClientVariant>>(
                (variant) => CheckedPopupMenuItem<KugouClientVariant>(
                  key: ValueKey<String>(
                    'kugou-client-variant-option-${variant.name}',
                  ),
                  value: variant,
                  checked: variant == selected,
                  child: Text(kugouClientVariantLabel(variant)),
                ),
              )
              .toList(growable: false),
      child: Semantics(
        button: true,
        label: '音源客户端，当前配置为$label',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            key: const ValueKey<String>('kugou-client-variant-button'),
            constraints: const BoxConstraints(minWidth: 122),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
