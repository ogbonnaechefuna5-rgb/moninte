import 'package:flutter/material.dart';

/// An app permission entry shown on the permissions screen.
class Permission {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final bool enabled;
  final bool required;
  final String status; // 'granted' | 'denied' | 'not-asked'

  const Permission({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.enabled,
    required this.required,
    required this.status,
  });

  Permission copyWith({bool? enabled, String? status}) => Permission(
        id: id,
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        description: description,
        enabled: enabled ?? this.enabled,
        required: required,
        status: status ?? this.status,
      );
}
