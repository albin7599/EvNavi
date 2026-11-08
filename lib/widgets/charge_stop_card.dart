import 'package:flutter/material.dart';
import '../models/trip_plan_model.dart';

class ChargeStopCard extends StatelessWidget {
  final ChargeStop stop;
  final int index;
  final VoidCallback onTap;

  const ChargeStopCard({
    super.key,
    required this.stop,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final station = stop.bestStation;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xEE161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Charge Stop $index',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.battery_charging_full,
                    color: Colors.orange, size: 16),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.route, color: Color(0xFF8B949E), size: 12),
                const SizedBox(width: 4),
                Text(
                  'At ${stop.distanceFromStartKm.toStringAsFixed(0)} km',
                  style:
                      const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
                ),
              ],
            ),
            if (station != null) ...[
              Text(
                station.name,
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.flash_on,
                      color: Color(0xFF00BCD4), size: 12),
                  const SizedBox(width: 2),
                  Text(
                    station.powerLabel,
                    style:
                        const TextStyle(color: Color(0xFF00BCD4), fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stop.stations.length} nearby',
                    style:
                        const TextStyle(color: Color(0xFF8B949E), fontSize: 10),
                  ),
                ],
              ),
            ] else
              const Text(
                'No station nearby',
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
