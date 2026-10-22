import 'package:flutter/material.dart';
import 'package:team_oustad_app/core/utils/platform_utils.dart';

/// A responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformUtils.getDeviceType(context);
    
    int columns;
    switch (deviceType) {
      case DeviceType.watch:
        columns = 1;
        break;
      case DeviceType.mobile:
        columns = 2;
        break;
      case DeviceType.desktop:
      case DeviceType.web:
        columns = PlatformUtils.isExtraLargeScreen(context) ? 4 : 3;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        
        List<Widget> rows = [];
        for (int i = 0; i < children.length; i += columns) {
          final rowChildren = <Widget>[];
          for (int j = 0; j < columns && i + j < children.length; j++) {
            rowChildren.add(
              SizedBox(
                width: itemWidth,
                child: children[i + j],
              ),
            );
            if (j < columns - 1 && i + j < children.length - 1) {
              rowChildren.add(SizedBox(width: spacing));
            }
          }
          
          // Fill remaining space if last row is incomplete
          while (rowChildren.length < columns * 2 - 1) {
            rowChildren.add(SizedBox(width: itemWidth));
            if (rowChildren.length < columns * 2 - 1) {
              rowChildren.add(SizedBox(width: spacing));
            }
          }
          
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
          
          if (i + columns < children.length) {
            rows.add(SizedBox(height: runSpacing));
          }
        }
        
        return Column(
          children: rows,
        );
      },
    );
  }
}

/// A responsive container with adaptive padding and max width for desktop
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? PlatformUtils.getResponsivePadding(context);
    final deviceType = PlatformUtils.getDeviceType(context);
    
    Widget content = Padding(
      padding: responsivePadding,
      child: child,
    );

    // On desktop, center content with max width
    if (deviceType == DeviceType.desktop || deviceType == DeviceType.web) {
      final maxContentWidth = maxWidth ?? 1400;
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Responsive text that adapts font size based on device
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final multiplier = PlatformUtils.getFontSizeMultiplier(context);
    final baseStyle = style ?? const TextStyle();
    final fontSize = (baseStyle.fontSize ?? 14.0) * multiplier;

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
