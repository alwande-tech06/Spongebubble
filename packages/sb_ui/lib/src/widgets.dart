import 'package:flutter/material.dart';
import 'package:sb_core/sb_core.dart';

import 'colors.dart';

/// Tones for badges and notes.
enum SbTone { info, success, warning, danger, neutral }

(Color, Color) toneColors(SbTone t) => switch (t) {
      SbTone.info => (SbColors.aquaSoft, SbColors.aquaDark),
      SbTone.success => (SbColors.greenSoft, SbColors.green),
      SbTone.warning => (SbColors.yellowSoft, SbColors.yellowInk),
      SbTone.danger => (SbColors.redSoft, SbColors.red),
      SbTone.neutral => (SbColors.grey, SbColors.ink2),
    };

SbTone toneForStatus(BookingStatus s) => switch (s) {
      BookingStatus.completed => SbTone.success,
      BookingStatus.cancelled => SbTone.danger,
      BookingStatus.findingProvider || BookingStatus.pendingPayment || BookingStatus.awaitingPayment => SbTone.warning,
      _ => SbTone.info,
    };

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = SbTone.info, this.icon});

  final String label;
  final SbTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class SbCard extends StatelessWidget {
  const SbCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.highlighted = false, this.color});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: highlighted ? SbColors.aquaDark : SbColors.line, width: highlighted ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class Note extends StatelessWidget {
  const Note(this.text, {super.key, this.tone = SbTone.info, this.icon = Icons.info_outline});

  final String text;
  final SbTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(tone);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: fg),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 12.5, height: 1.4))),
      ]),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.7, color: SbColors.ink3)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key, this.strong = false, this.valueColor});

  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: strong ? 15 : 13.5, color: strong ? SbColors.ink : SbColors.ink2, fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: strong ? 15 : 13.5, fontWeight: FontWeight.w600, color: valueColor ?? SbColors.ink)),
          ),
        ]),
      );
}

/// Price breakdown used on review, pay and receipt screens.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({super.key, required this.quote, required this.service, required this.category, this.payNow = true});

  final PriceQuote quote;
  final ServiceType service;
  final VehicleCategory category;
  final bool payNow;

  @override
  Widget build(BuildContext context) {
    return SbCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        KeyValue('${service.label} (${category.label})', rand(quote.servicePrice)),
        KeyValue('Travel fee (est. ${quote.distanceKm.toStringAsFixed(0)} km × R${Pricing.travelRatePerKm})', rand(quote.travelFee)),
        const Divider(),
        KeyValue('Pay washer after the wash', rand(quote.balance)),
        const Divider(),
        KeyValue(payNow ? 'Booking fee · pay now' : 'Booking fee (paid)', rand(quote.bookingFee), strong: true, valueColor: SbColors.aquaDark),
      ]),
    );
  }
}

/// 5-step tracker: Accepted, Travelling, Arrived, Washing, Done.
class Milestones extends StatelessWidget {
  const Milestones({super.key, required this.current});

  final int current;
  static const steps = ['Accepted', 'Travelling', 'Arrived', 'Washing', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(children: [
              Row(children: [
                Expanded(child: Container(height: 3, color: i == 0 ? Colors.transparent : (i <= current ? SbColors.green : SbColors.line))),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current ? SbColors.green : (i == current ? SbColors.aquaDark : SbColors.line),
                    border: i == current ? Border.all(color: SbColors.aquaSoft, width: 4) : null,
                  ),
                  child: i < current ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                ),
                Expanded(child: Container(height: 3, color: i == steps.length - 1 ? Colors.transparent : (i < current ? SbColors.green : SbColors.line))),
              ]),
              const SizedBox(height: 6),
              Text(steps[i],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w600,
                      color: i <= current ? SbColors.ink : SbColors.ink3)),
            ]),
          ),
      ],
    );
  }
}

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.step, required this.total});

  final int step; // 1-based
  final int total;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: i < step ? SbColors.aquaDark : SbColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ]);
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 40, this.background = SbColors.aquaSoft, this.foreground = SbColors.aquaDark});

  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(initials, style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
      );
}

/// Grey box standing in for a photo, map or document.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({super.key, required this.label, this.sub = '', this.taken = true, this.damage = false, this.height = 96, this.onTap});

  final String label;
  final String sub;
  final bool taken;
  final bool damage;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = damage ? (SbColors.redSoft, SbColors.red) : (taken ? (SbColors.aquaSoft, SbColors.aquaDark) : (Colors.white, SbColors.ink3));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: taken ? null : Border.all(color: SbColors.ink3, width: 1.2),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(damage ? Icons.error_outline : (taken ? Icons.image_outlined : Icons.photo_camera_outlined), color: fg, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w600)),
          if (sub.isNotEmpty) Text(sub, style: TextStyle(color: fg.withAlpha(200), fontSize: 11)),
        ]),
      ),
    );
  }
}

/// Simple stand-in map until the Google Maps SDK is wired in.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, this.height = 220, this.label = 'Map', this.showRoute = false});

  final double height;
  final String label;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFE6F0F2), borderRadius: BorderRadius.circular(16)),
      child: CustomPaint(
        painter: _MapPainter(showRoute),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withAlpha(220), borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SbColors.ink2)),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.route);

  final bool route;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (i + 0.5) / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + (i.isEven ? 14 : -10)), road);
      final x = size.width * (i + 0.5) / 6;
      canvas.drawLine(Offset(x, 0), Offset(x - 30, size.height), road..strokeWidth = 3);
    }
    if (route) {
      final p = Paint()
        ..color = SbColors.aquaDark
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(size.width * 0.2, size.height * 0.8)
        ..lineTo(size.width * 0.35, size.height * 0.55)
        ..lineTo(size.width * 0.55, size.height * 0.5)
        ..lineTo(size.width * 0.75, size.height * 0.25);
      canvas.drawPath(path, p);
      canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 9, Paint()..color = SbColors.aquaDark);
      canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.25), 9, Paint()..color = SbColors.yellow);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.route != route;
}

/// Primary call to action pinned to the bottom of a screen.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 10), children[i]],
          ]),
        ),
      );
}

/// Centres content on wide screens (web) and keeps phone width.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
