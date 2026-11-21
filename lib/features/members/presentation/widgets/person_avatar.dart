import 'package:flutter/material.dart';

import 'package:gia_pha/features/members/domain/entities/person.dart';

MaterialColor genderColor(Gender g) => switch (g) {
      Gender.male => Colors.blue,
      Gender.female => Colors.pink,
      Gender.other => Colors.grey,
    };

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.person, {super.key, this.radius = 20});

  final Person person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = genderColor(person.gender);
    final parts = person.fullName.trim().split(RegExp(r'\s+'));
    final initial = parts.last.isEmpty ? '?' : parts.last[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.shade100,
      foregroundColor: color.shade900,
      child: Text(initial, style: TextStyle(fontSize: radius * 0.9)),
    );
  }
}
