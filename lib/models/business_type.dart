import 'package:flutter/material.dart';

/// Business types supported by the application
enum BusinessType { wedding, photography, catering, eventPlanning, general }

/// Configuration for a specific business type
class BusinessConfig {
  final BusinessType type;
  final String displayName;
  final String appTitle;
  final String pdfTitle; // New: Title for PDF reports
  final IconData primaryIcon;
  final IconData eventIcon;
  final Color accentColor;

  // Field labels
  final String eventLabel; // e.g., "Wedding Dates", "Session Dates"
  final String eventLabelSingular; // e.g., "Wedding Date", "Session Date"
  final String client1Label; // e.g., "Bride", "Client"
  final String client2Label; // e.g., "Groom", "Client 2"
  final String customerLabel; // e.g., "Customer", "Client"
  final bool showClientFields; // Whether to show client 1/2 fields
  final bool showEventCategory; // New: Whether to show Male/Female selector

  // Empty state messages
  final String emptyStateMessage;

  const BusinessConfig({
    required this.type,
    required this.displayName,
    required this.appTitle,
    required this.pdfTitle,
    required this.primaryIcon,
    required this.eventIcon,
    required this.accentColor,
    required this.eventLabel,
    required this.eventLabelSingular,
    required this.client1Label,
    required this.client2Label,
    required this.customerLabel,
    required this.showClientFields,
    required this.showEventCategory,
    required this.emptyStateMessage,
  });

  /// Get configuration for a specific business type
  factory BusinessConfig.fromType(BusinessType type) {
    switch (type) {
      case BusinessType.wedding:
        return const BusinessConfig(
          type: BusinessType.wedding,
          displayName: 'Wedding Studio',
          appTitle: 'BizLedger',
          pdfTitle: 'Wedding Report',
          primaryIcon: Icons.favorite,
          eventIcon: Icons.calendar_today,
          accentColor: Color(0xFFD4AF37), // Gold
          eventLabel: 'Wedding Dates',
          eventLabelSingular: 'Wedding Date',
          client1Label: 'Bride',
          client2Label: 'Groom',
          customerLabel: 'Customer Name',
          showClientFields: true,
          showEventCategory: true,
          emptyStateMessage:
              'No weddings booked yet.\nTap + to create your first booking.',
        );

      case BusinessType.photography:
        return const BusinessConfig(
          type: BusinessType.photography,
          displayName: 'Photography Studio',
          appTitle: 'PhotoBook',
          pdfTitle: 'Photography Report',
          primaryIcon: Icons.camera_alt,
          eventIcon: Icons.photo_camera,
          accentColor: Color(0xFF6366F1), // Indigo
          eventLabel: 'Session Dates',
          eventLabelSingular: 'Session Date',
          client1Label: 'Client Name',
          client2Label: 'Partner Name',
          customerLabel: 'Client Name',
          showClientFields: false,
          showEventCategory: false,
          emptyStateMessage:
              'No photoshoots booked yet.\nTap + to schedule your first session.',
        );

      case BusinessType.catering:
        return const BusinessConfig(
          type: BusinessType.catering,
          displayName: 'Catering Service',
          appTitle: 'CaterPro',
          pdfTitle: 'Catering Report',
          primaryIcon: Icons.restaurant,
          eventIcon: Icons.event,
          accentColor: Color(0xFFEF4444), // Red
          eventLabel: 'Service Dates',
          eventLabelSingular: 'Service Date',
          client1Label: 'Contact Person',
          client2Label: 'Secondary Contact',
          customerLabel: 'Client Name',
          showClientFields: false,
          showEventCategory: false,
          emptyStateMessage:
              'No catering orders yet.\nTap + to add your first booking.',
        );

      case BusinessType.eventPlanning:
        return const BusinessConfig(
          type: BusinessType.eventPlanning,
          displayName: 'Event Planning',
          appTitle: 'EventMaster',
          pdfTitle: 'Event Report',
          primaryIcon: Icons.celebration,
          eventIcon: Icons.event_available,
          accentColor: Color(0xFF8B5CF6), // Purple
          eventLabel: 'Event Dates',
          eventLabelSingular: 'Event Date',
          client1Label: 'Organizer',
          client2Label: 'Co-Organizer',
          customerLabel: 'Client Name',
          showClientFields: false,
          showEventCategory: false,
          emptyStateMessage:
              'No events planned yet.\nTap + to create your first event.',
        );

      case BusinessType.general:
        return const BusinessConfig(
          type: BusinessType.general,
          displayName: 'General Business',
          appTitle: 'BookingPro',
          pdfTitle: 'Business Report',
          primaryIcon: Icons.business,
          eventIcon: Icons.event_note,
          accentColor: Color(0xFF10B981), // Green
          eventLabel: 'Service Dates',
          eventLabelSingular: 'Service Date',
          client1Label: 'Client',
          client2Label: 'Contact Person',
          customerLabel: 'Customer Name',
          showClientFields: false,
          showEventCategory: false,
          emptyStateMessage:
              'No bookings yet.\nTap + to create your first booking.',
        );
    }
  }

  /// Convert to string for storage
  String toJson() => type.name;

  /// Create from string
  static BusinessType fromJson(String json) {
    return BusinessType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => BusinessType.wedding,
    );
  }

  /// Get all available business types
  static List<BusinessConfig> getAll() {
    return BusinessType.values
        .map((type) => BusinessConfig.fromType(type))
        .toList();
  }
}
