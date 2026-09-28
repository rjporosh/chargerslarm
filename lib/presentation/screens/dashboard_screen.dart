import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/alarm_status.dart';
import '../../domain/models/charging_connection_state.dart';
import '../../l10n/app_localizations.dart';
import '../controllers/dashboard_controller.dart';
import '../responsive/responsive_layout.dart';
import '../widgets/battery_gauge.dart';
import '../widgets/status_card.dart';
import '../widgets/target_chip.dart';
import 'custom_target_sheet.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Consumer<DashboardController>(
          builder: (context, controller, _) {
            if (!controller.initialized) {
              return const Center(child: CircularProgressIndicator());
            }
            final reading = controller.reading;
            if (reading == null) {
              return _ErrorOrEmptyState(controller: controller, l10n: l10n);
            }

            return AdaptiveLayout(
              compact: (_) => _PortraitDashboard(controller: controller, l10n: l10n),
              expanded: (_) => _WideDashboard(controller: controller, l10n: l10n),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorOrEmptyState extends StatelessWidget {
  const _ErrorOrEmptyState({required this.controller, required this.l10n});

  final DashboardController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hasError = controller.lastError != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.hourglass_top_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasError ? l10n.errorStateTitle : l10n.emptyStateNoReading,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasError) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.initialize,
                child: Text(l10n.errorStateRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared content pieces used by both the compact and wide layouts, so the
/// two only differ in arrangement, never in behavior or copy.
class _DashboardContent {
  const _DashboardContent(this.controller, this.l10n);

  final DashboardController controller;
  final AppLocalizations l10n;

  bool get targetReached => controller.status == AlarmStatus.sounding;

  Widget gauge() {
    final r = controller.reading!;
    return BatteryGauge(
      percentage: r.percentage,
      targetPercentage: controller.settings.targetPercentage,
      isCharging: r.isCharging,
      targetReached: targetReached,
    );
  }

  Widget alarmBanner(BuildContext context) {
    if (controller.status != AlarmStatus.sounding) return const SizedBox.shrink();
    final reachedHundred = controller.reading!.percentage >= 100;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reachedHundred
                    ? l10n.batteryFullMessage
                    : l10n.targetReachedMessage(controller.settings.targetPercentage),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.dismissAlarm,
              child: Text(l10n.dismissAlarm),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusRow(BuildContext context) {
    final r = controller.reading!;
    final chargerLabel = switch (r.connectionState) {
      ChargingConnectionState.disconnected => l10n.chargerStatusDisconnected,
      ChargingConnectionState.charging => l10n.chargerStatusCharging,
      ChargingConnectionState.connectedFull => l10n.chargerStatusFull,
    };
    final alarmLabel = switch (controller.status) {
      AlarmStatus.idle => l10n.alarmStatusIdle,
      AlarmStatus.sounding => l10n.alarmStatusSounding,
      AlarmStatus.dismissed => l10n.alarmStatusDismissed,
      AlarmStatus.disabled => l10n.alarmStatusDisabled,
    };

    return Row(
      children: [
        Expanded(
          child: StatusCard(
            icon: r.isCharging ? Icons.bolt_rounded : Icons.power_off_rounded,
            label: l10n.chargerStatusLabel,
            value: chargerLabel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatusCard(
            icon: Icons.notifications_rounded,
            label: l10n.alarmStatusLabel,
            value: alarmLabel,
            emphasisColor: controller.status == AlarmStatus.sounding
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
      ],
    );
  }

  Widget quickTargets(BuildContext context) {
    final current = controller.settings.targetPercentage;
    final isPreset = current == 80 || current == 100;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        TargetChip(
          label: l10n.targetOptionPercent(80),
          selected: current == 80,
          onTap: () => controller.setTarget(80),
        ),
        TargetChip(
          label: l10n.targetOptionPercent(100),
          selected: current == 100,
          onTap: () => controller.setTarget(100),
        ),
        TargetChip(
          label: isPreset ? l10n.targetOptionCustom : l10n.targetOptionPercent(current),
          selected: !isPreset,
          icon: Icons.tune_rounded,
          onTap: () async {
            final value = await CustomTargetSheet.show(context, initialValue: current);
            if (value != null) {
              await controller.setTarget(value);
            }
          },
        ),
      ],
    );
  }
}

class _PortraitDashboard extends StatelessWidget {
  const _PortraitDashboard({required this.controller, required this.l10n});

  final DashboardController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final content = _DashboardContent(controller, l10n);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        content.alarmBanner(context),
        if (controller.status == AlarmStatus.sounding) const SizedBox(height: 16),
        Center(child: content.gauge()),
        const SizedBox(height: 24),
        content.statusRow(context),
        const SizedBox(height: 24),
        Text(l10n.quickTargetsTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        content.quickTargets(context),
      ],
    );
  }
}

class _WideDashboard extends StatelessWidget {
  const _WideDashboard({required this.controller, required this.l10n});

  final DashboardController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final content = _DashboardContent(controller, l10n);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Center(child: content.gauge()),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 5,
            child: ListView(
              shrinkWrap: true,
              children: [
                content.alarmBanner(context),
                if (controller.status == AlarmStatus.sounding) const SizedBox(height: 16),
                content.statusRow(context),
                const SizedBox(height: 24),
                Text(l10n.quickTargetsTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                content.quickTargets(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
