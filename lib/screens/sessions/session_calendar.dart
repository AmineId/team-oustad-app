import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import 'session_widgets.dart';

/// Charge les séances de l'intervalle [from, to[ ; null en cas d'erreur.
typedef SessionRangeLoader =
    Future<List<Map<String, dynamic>>?> Function(DateTime from, DateTime to);

enum SessionCalendarView { week, month }

/// Calendrier des séances : semaine en grille horaire ou mois en grille de
/// jours (les séances du jour choisi s'affichent dessous). Charge lui-même
/// la période affichée via [loader] ; un changement de [filters] recharge.
class SessionCalendar extends StatefulWidget {
  final SessionRangeLoader loader;

  /// Ouvre une séance ; renvoie true si elle a changé (rechargement).
  final Future<bool?> Function(Map<String, dynamic> session) onSessionTap;

  /// Créneau vide touché (vue semaine) ; null = pas de création.
  final ValueChanged<DateTime>? onSlotTap;

  /// Filtres du parent (salle, coach, type) : les changer recharge.
  final Object? filters;

  const SessionCalendar({
    super.key,
    required this.loader,
    required this.onSessionTap,
    this.onSlotTap,
    this.filters,
  });

  @override
  State<SessionCalendar> createState() => SessionCalendarState();
}

class SessionCalendarState extends State<SessionCalendar> {
  static const _firstHour = 6;
  static const _lastHour = 23;
  static const _hourHeight = 56.0;
  static const _gutter = 40.0;

  SessionCalendarView _view = SessionCalendarView.week;
  DateTime _anchor = DateUtils.dateOnly(DateTime.now());
  late DateTime _selectedDay = _anchor;
  List<Map<String, dynamic>>? _sessions;
  bool _isLoading = true;
  int _request = 0;

  final ScrollController _hoursController = ScrollController(
    initialScrollOffset: (8 - _firstHour) * _hourHeight,
  );

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(SessionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) reload();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  static DateTime _mondayOf(DateTime d) =>
      DateUtils.dateOnly(d).subtract(Duration(days: d.weekday - 1));

  /// Premier jour affiché et lendemain du dernier.
  (DateTime, DateTime) get _range {
    if (_view == SessionCalendarView.week) {
      final start = _mondayOf(_anchor);
      return (start, DateUtils.addDaysToDate(start, 7));
    }
    final start = _mondayOf(DateTime(_anchor.year, _anchor.month));
    final next = DateTime(_anchor.year, _anchor.month + 1);
    final end = _mondayOf(DateUtils.addDaysToDate(next, 6));
    return (start, end);
  }

  Future<void> reload() async {
    final request = ++_request;
    setState(() => _isLoading = true);
    final (from, to) = _range;
    final sessions = await widget.loader(from, to);
    // Une navigation plus récente a déjà relancé un chargement.
    if (!mounted || request != _request) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  void _shift(int step) {
    setState(() {
      _anchor = _view == SessionCalendarView.week
          ? DateUtils.addDaysToDate(_anchor, 7 * step)
          : DateTime(_anchor.year, _anchor.month + step);
      _selectedDay = _view == SessionCalendarView.week
          ? DateUtils.addDaysToDate(_selectedDay, 7 * step)
          : _anchor;
    });
    reload();
  }

  void _goToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() => _anchor = _selectedDay = today);
    reload();
  }

  void _setView(SessionCalendarView view) {
    setState(() {
      _view = view;
      _anchor = _selectedDay;
    });
    reload();
  }

  Future<void> _open(Map<String, dynamic> session) async {
    if (await widget.onSessionTap(session) == true) reload();
  }

  List<Map<String, dynamic>> _ofDay(DateTime day) {
    final list = (_sessions ?? []).where((s) {
      final start = SessionService.startOf(s);
      return start != null && DateUtils.isSameDay(start, day);
    }).toList();
    list.sort(
      (a, b) =>
          SessionService.startOf(a)!.compareTo(SessionService.startOf(b)!),
    );
    return list;
  }

  String get _title {
    if (_view == SessionCalendarView.month) {
      return '${sessionMonth(_anchor)} ${_anchor.year}';
    }
    final (start, end) = _range;
    return '${sessionDay(start)} – '
        '${sessionDay(DateUtils.addDaysToDate(end, -1))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Aujourd\'hui',
                onPressed: _goToday,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Précédent',
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Suivant',
                onPressed: () => _shift(1),
              ),
              _view == SessionCalendarView.week
                  ? IconButton(
                      icon: const Icon(Icons.calendar_month),
                      tooltip: 'Vue mois',
                      onPressed: () => _setView(SessionCalendarView.month),
                    )
                  : IconButton(
                      icon: const Icon(Icons.calendar_view_week),
                      tooltip: 'Vue semaine',
                      onPressed: () => _setView(SessionCalendarView.week),
                    ),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        if (!_isLoading && _sessions == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Impossible de charger le planning',
              style: TextStyle(color: context.palette.error),
            ),
          ),
        Expanded(
          child: _view == SessionCalendarView.week
              ? _buildWeek(theme)
              : _buildMonth(theme),
        ),
      ],
    );
  }

  // --- Semaine -------------------------------------------------------------

  Widget _buildWeek(ThemeData theme) {
    final (start, _) = _range;
    final days = [
      for (var i = 0; i < 7; i++) DateUtils.addDaysToDate(start, i),
    ];
    final today = DateUtils.dateOnly(DateTime.now());
    final divider = theme.dividerColor.withValues(alpha: 0.4);
    const gridHeight = (_lastHour - _firstHour) * _hourHeight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: _gutter, top: 4, bottom: 4),
          child: Row(
            children: [
              for (final day in days)
                Expanded(child: _dayHeader(day, day == today, theme)),
            ],
          ),
        ),
        Divider(height: 1, color: divider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: reload,
            child: SingleChildScrollView(
              controller: _hoursController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              child: SizedBox(
                height: gridHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _gutter,
                      child: Stack(
                        children: [
                          for (var h = _firstHour; h < _lastHour; h++)
                            Positioned(
                              top: (h - _firstHour) * _hourHeight + 2,
                              right: 6,
                              child: Text(
                                '${h.toString().padLeft(2, '0')}h',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final day in days)
                      Expanded(child: _dayColumn(day, day == today, divider)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayHeader(DateTime day, bool isToday, ThemeData theme) {
    final palette = context.palette;
    return Column(
      children: [
        Text(sessionWeekday(day), style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(
                  color: palette.primaryFill,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '${day.day}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isToday ? palette.onPrimary : null,
              fontWeight: isToday ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(DateTime day, bool isToday, Color divider) {
    final placed = _layoutDay(_ofDay(day));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: widget.onSlotTap == null
              ? null
              : (d) {
                  // Créneau à l'heure pleine sous le doigt.
                  final hour =
                      _firstHour + (d.localPosition.dy / _hourHeight).floor();
                  widget.onSlotTap!(day.add(Duration(hours: hour)));
                },
          child: Container(
            decoration: BoxDecoration(
              color: isToday
                  ? context.palette.primary.withValues(alpha: 0.05)
                  : null,
              border: Border(left: BorderSide(color: divider)),
            ),
            child: Stack(
              children: [
                for (var h = 1; h < _lastHour - _firstHour; h++)
                  Positioned(
                    top: h * _hourHeight,
                    left: 0,
                    right: 0,
                    child: Divider(height: 1, color: divider),
                  ),
                for (final p in placed)
                  Positioned(
                    top: p.top,
                    height: p.height,
                    left: width * p.lane / p.lanes + 1,
                    width: width / p.lanes - 2,
                    child: _SessionBlock(
                      session: p.session,
                      onTap: () => _open(p.session),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Positionne les séances d'un jour : les séances qui se chevauchent se
  /// partagent la largeur de la colonne.
  List<_Placed> _layoutDay(List<Map<String, dynamic>> sessions) {
    final placed = <_Placed>[];
    var cluster = <_Placed>[];
    var clusterEnd = DateTime(0);
    final laneEnds = <DateTime>[];

    void closeCluster() {
      for (final p in cluster) {
        p.lanes = laneEnds.length;
      }
      placed.addAll(cluster);
      cluster = [];
      laneEnds.clear();
    }

    for (final s in sessions) {
      final start = SessionService.startOf(s)!;
      final end =
          SessionService.endOf(s) ?? start.add(const Duration(hours: 1));
      if (cluster.isNotEmpty && !start.isBefore(clusterEnd)) closeCluster();
      var lane = laneEnds.indexWhere((e) => !start.isBefore(e));
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(end);
      } else {
        laneEnds[lane] = end;
      }
      if (end.isAfter(clusterEnd) || cluster.isEmpty) clusterEnd = end;

      final dayStart = DateTime(start.year, start.month, start.day, _firstHour);
      const maxTop = (_lastHour - _firstHour) * _hourHeight;
      final top = (start.difference(dayStart).inMinutes / 60 * _hourHeight)
          .clamp(0.0, maxTop - 20);
      final height = (end.difference(start).inMinutes / 60 * _hourHeight).clamp(
        20.0,
        maxTop - top,
      );
      cluster.add(_Placed(s, top, height, lane));
    }
    closeCluster();
    return placed;
  }

  // --- Mois ----------------------------------------------------------------

  Widget _buildMonth(ThemeData theme) {
    final (start, end) = _range;
    final days = [
      for (var d = start; d.isBefore(end); d = DateUtils.addDaysToDate(d, 1)) d,
    ];
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = _ofDay(_selectedDay);

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
        children: [
          Row(
            children: [
              for (final d in days.take(7))
                Expanded(
                  child: Text(
                    sessionWeekday(d),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var w = 0; w < days.length; w += 7)
            Row(
              children: [
                for (final d in days.sublist(w, w + 7))
                  Expanded(
                    child: _monthCell(
                      d,
                      inMonth: d.month == _anchor.month,
                      isToday: d == today,
                      isSelected: d == _selectedDay,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: Text(
              sessionDay(_selectedDay),
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (selected.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('Aucune séance', style: theme.textTheme.bodySmall),
            ),
          for (final s in selected)
            SessionCard(session: s, onTap: () => _open(s)),
        ],
      ),
    );
  }

  Widget _monthCell(
    DateTime day, {
    required bool inMonth,
    required bool isToday,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final palette = context.palette;
    final sessions = _ofDay(day);
    final textColor = isToday
        ? palette.onPrimary
        : inMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.35);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: palette.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(
                      color: palette.primaryFill,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final s in sessions.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: sessionTypeColor(
                          context,
                          SessionService.typeOf(s),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (sessions.length > 3)
                    Text('+', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placed {
  final Map<String, dynamic> session;
  final double top;
  final double height;
  final int lane;
  int lanes = 1;

  _Placed(this.session, this.top, this.height, this.lane);
}

/// Bloc d'une séance dans la grille horaire.
class _SessionBlock extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;

  const _SessionBlock({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = SessionService.typeOf(session);
    final color = sessionTypeColor(context, type);
    final cancelled = session['status'] == 'cancelled';
    final start = SessionService.startOf(session);
    final title = session['title'] as String?;
    final label = (title == null || title.isEmpty)
        ? SessionService.types[type]!
        : title;
    final style = TextStyle(
      fontSize: 10,
      height: 1.15,
      color: Theme.of(context).colorScheme.onSurface,
      decoration: cancelled ? TextDecoration.lineThrough : null,
    );
    return Material(
      color: color.withValues(alpha: cancelled ? 0.08 : 0.18),
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (start != null)
                Text(
                  sessionTime(start),
                  style: style.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              Flexible(
                child: Text(
                  '$label · ${sessionCoachName(session)}',
                  style: style,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
