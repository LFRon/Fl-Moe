import 'package:material_ui/material_ui.dart';

final class InlineMessage extends StatelessWidget {
  const InlineMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(message),
  );
}
