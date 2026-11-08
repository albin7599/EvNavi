import 'dart:math';
import 'package:flutter/material.dart';
import '../models/station_model.dart';

class StationMarker extends StatelessWidget {
  final Station station;
  final double zoom;
  final bool isPlannedStop;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    required this.zoom,
    this.isPlannedStop = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double baseSize = max(14.0, (zoom - 7) * 4);
    final double size = isPlannedStop ? baseSize * 1.3 : baseSize;
    final double iconSize = size * 0.65;

    final Color primaryColor = isPlannedStop
        ? const Color(0xFF222222) // Softer black for planned stops
        : (station.isOperational ? const Color(0xFF008F47) : const Color(0xFF222222).withValues(alpha: 0.4));

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white, // Clean white background
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isPlannedStop ? Icons.bolt_rounded : Icons.bolt,
              color: primaryColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
