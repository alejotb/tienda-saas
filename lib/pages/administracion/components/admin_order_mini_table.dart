import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';

class AdminOrderMiniTable<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final List<AdminTableColumn<T>> columns;
  final Widget actionButton;
  final Function(T item) onActionPressed;
  final Function(T item) onOrderTap;
  final Color accentColor;
  final Widget? rejectButton;
  final Function(T item)? onRejectPressed;

  const AdminOrderMiniTable({
    super.key,
    required this.title,
    required this.items,
    required this.columns,
    required this.actionButton,
    required this.onActionPressed,
    required this.onOrderTap,
    this.accentColor = Colors.blue,
    this.rejectButton,
    this.onRejectPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            title,
            style: FlutterFlowTheme.of(context).titleLarge.override(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 410),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => onOrderTap(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        ...columns.map((col) => Expanded(
                          flex: col.flex,
                          child: Text(
                            col.getValue(item),
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontWeight: columns.indexOf(col) == 0 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(
                            Icons.visibility_outlined,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 20,
                          ),
                          onPressed: () => onOrderTap(item),
                          tooltip: 'Ver más detalles',
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onActionPressed(item),
                          child: actionButton,
                        ),
                        if (rejectButton != null && onRejectPressed != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onRejectPressed!(item),
                            child: rejectButton!,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AdminTableColumn<T> {
  final String header;
  final String Function(T item) getValue;
  final int flex;

  AdminTableColumn({
    required this.header,
    required this.getValue,
    this.flex = 1,
  });
}
