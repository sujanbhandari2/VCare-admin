import 'package:flutter/material.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/loadable_list_view.dart';

import '../../core/state/loadable_list_state_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('LoadableListView', () {
    testWidgets('shows header during initial loading state', (tester) async {
      final state = LoadableListState<ListItem>().loading();

      await tester.pumpWidget(
        _wrap(
          LoadableListView<ListItem>(
            state: state,
            headerBuilder: (_) =>
                const Text('Header Loading', key: ValueKey('header_loading')),
            itemBuilder: (_, item, index) => Text('$item'),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('header_loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator on initial loading', (tester) async {
      final state = LoadableListState<ListItem>().loading();

      await tester.pumpWidget(
        _wrap(
          LoadableListView<ListItem>(
            state: state,
            itemBuilder: (_, item, index) => Text('$item'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error and retry button on initial error', (
      tester,
    ) async {
      final state = LoadableListState<ListItem>().failure('Load failed');

      await tester.pumpWidget(
        _wrap(
          LoadableListView<ListItem>(
            state: state,
            itemBuilder: (_, item, index) => Text('$item'),
            onRefresh: () async {},
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Load failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('triggers onLoadMore when scrolled near end', (tester) async {
      int loadMoreCalled = 0;
      final state = LoadableListState<ListItem>().success(
        items: List<ListItem>.generate(50, (index) => ListItem.value(index)),
        total: 100,
      );

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 320,
            child: LoadableListView<ListItem>(
              state: state,
              loadMoreTriggerThreshold: 10000,
              onLoadMore: () async {
                loadMoreCalled += 1;
              },
              itemBuilder: (_, item, index) =>
                  SizedBox(height: 48, child: Text('Item $item')),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();

      expect(loadMoreCalled, greaterThanOrEqualTo(1));
    });

    testWidgets('renders custom header and footer as list children', (
      tester,
    ) async {
      final state = LoadableListState<ListItem>().success(
        items: [ListItem.value(1), ListItem.value(2)],
        total: 100,
      );

      await tester.pumpWidget(
        _wrap(
          LoadableListView<ListItem>(
            state: state,
            headerBuilder: (context) =>
                const Text('Header A', key: ValueKey('header_a')),
            footerBuilder: (context) =>
                const Text('Footer A', key: ValueKey('footer_a')),
            itemBuilder: (_, item, index) =>
                Text('Item $item', key: ValueKey('item_$item')),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('header_a')), findsOneWidget);
      expect(find.byKey(const ValueKey('item_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('item_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('footer_a')), findsOneWidget);

      final headerDy = tester
          .getTopLeft(find.byKey(const ValueKey('header_a')))
          .dy;
      final firstItemDy = tester
          .getTopLeft(find.byKey(const ValueKey('item_1')))
          .dy;
      final footerDy = tester
          .getTopLeft(find.byKey(const ValueKey('footer_a')))
          .dy;

      expect(headerDy, lessThan(firstItemDy));
      expect(firstItemDy, lessThan(footerDy));
    });

    testWidgets('shows load-more error footer when append fails', (
      tester,
    ) async {
      final state = LoadableListState<ListItem>()
          .success(
            items: [ListItem.value(1), ListItem.value(2), ListItem.value(3)],
            total: 100,
          )
          .appendFailure('Load more failed');

      await tester.pumpWidget(
        _wrap(
          LoadableListView<ListItem>(
            state: state,
            onLoadMore: () async {},
            itemBuilder: (_, item, index) =>
                SizedBox(height: 48, child: Text('Item $item')),
          ),
        ),
      );

      expect(find.text('Load more failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
