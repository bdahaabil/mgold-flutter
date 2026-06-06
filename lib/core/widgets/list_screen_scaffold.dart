import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'empty_state.dart';

class ListScreenScaffold extends StatelessWidget {
  const ListScreenScaffold({
    super.key,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.onRefresh,
    this.isLoading = false,
    this.error,
    this.isEmpty = false,
    this.emptyMessage = 'Nothing here yet.',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? emptyAction;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text('Error: $error', textAlign: TextAlign.center),
        ),
      );
    }
    if (isEmpty) {
      return EmptyState(
        message: emptyMessage,
        icon: emptyIcon,
        action: emptyAction,
      );
    }

    final list = ListView.builder(
      padding: padding ?? EdgeInsets.all(16.w),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );

    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
