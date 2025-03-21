
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:saber/components/home/preview_card.dart';
import 'package:saber/pages/editor/editor.dart';

class MasonryFiles extends StatelessWidget {
  const MasonryFiles({
    super.key,
    required this.files,
    required this.onTap,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  final List<String> files;
  final Function(String) onTap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MasonryGridView.count(
        itemCount: files.length,
        crossAxisCount: constraints.maxWidth ~/ 300 + 1,
        shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        physics: physics,
        itemBuilder: (context, index) => PreviewCard(
          filePath: files[index],
          onTap: onTap,
        ),
      ),
    );
  }
}