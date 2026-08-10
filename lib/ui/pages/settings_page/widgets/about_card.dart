import 'package:flutter/material.dart';

final class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 31,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/app_mascot.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Fl-Moe',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  'Flutter 原生桌面音乐客户端 · 纯 Dart 酷狗 API · GPLv2',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Chip(label: Text('Windows · Wayland')),
        ],
      ),
    ),
  );
}
