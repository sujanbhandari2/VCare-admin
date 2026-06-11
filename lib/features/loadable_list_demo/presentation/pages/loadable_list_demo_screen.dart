import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vcare_admin/features/loadable_list_demo/domain/models/demo_list_item.dart';

import 'package:vcare_admin/features/loadable_list_demo/presentation/providers/loadable_list_demo_state_provider.dart';
import 'package:vcare_admin/shared/widgets/loadable_list_view.dart';

class LoadableListDemoScreen extends ConsumerStatefulWidget {
  const LoadableListDemoScreen({super.key});

  @override
  ConsumerState<LoadableListDemoScreen> createState() =>
      _LoadableListDemoScreenState();
}

class _LoadableListDemoScreenState
    extends ConsumerState<LoadableListDemoScreen> {
  bool _simulateEmpty = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(loadableListDemoStateProvider.notifier).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loadableListDemoStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loadable List Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref
                        .read(loadableListDemoStateProvider.notifier)
                        .failNextInitialLoad();
                  },
                  child: const Text('Fail Next Initial'),
                ),
                OutlinedButton(
                  onPressed: () {
                    ref
                        .read(loadableListDemoStateProvider.notifier)
                        .failNextLoadMoreRequest();
                  },
                  child: const Text('Fail Next Load More'),
                ),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(loadableListDemoStateProvider.notifier)
                        .loadInitial();
                  },
                  child: const Text('Reload'),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Simulate Empty List'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            value: _simulateEmpty,
            onChanged: (value) {
              setState(() {
                _simulateEmpty = value;
              });
              ref
                  .read(loadableListDemoStateProvider.notifier)
                  .setSimulateEmpty(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items: ${state.items.length} | hasMore: ${state.hasMore}',
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LoadableListView<DemoListItem>(
              state: state,
              onRefresh: () =>
                  ref.read(loadableListDemoStateProvider.notifier).refresh(),
              onLoadMore: () =>
                  ref.read(loadableListDemoStateProvider.notifier).loadMore(),
              itemBuilder: (context, item, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text('$item')),
                  title: Text('Demo Item #$item'),
                  subtitle: Text('Index $index'),
                );
              },
              headerBuilder: (_) => Container(
                padding: const EdgeInsets.all(16),
                child: const Text("This is header"),
              ),
              headerBehavior: LoadableListHeaderBehavior.pinned,
              headerExtent: 60,
            ),
          ),
        ],
      ),
    );
  }
}
