import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../widget_marker_google_map.dart';

class MarkerGenerator extends StatefulWidget {
  const MarkerGenerator({
    Key? key,
    required this.widgetMarkers,
    required this.onMarkerGenerated,
  }) : super(key: key);
  final List<WidgetMarker> widgetMarkers;
  final ValueChanged<List<Marker>> onMarkerGenerated;

  @override
  _MarkerGeneratorState createState() => _MarkerGeneratorState();
}

class _MarkerGeneratorState extends State<MarkerGenerator> {
  List<GlobalKey> globalKeys = [];
  List<WidgetMarker> lastMarkers = [];

 Future<Marker> _convertToMarker(GlobalKey key) async {
  int index = globalKeys.indexOf(key);
  if (index == -1) {
    // Handle the case where the key is not found in globalKeys
    throw Exception('Key not found in globalKeys');
  }
  final widgetMarker = widget.widgetMarkers[index];
  RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final byteData =
      await image.toByteData(format: ImageByteFormat.png) ?? ByteData(0);
  final uint8List = byteData.buffer.asUint8List();
  return Marker(
    onTap: widgetMarker.onTap,
    markerId: MarkerId(widgetMarker.markerId),
    position: widgetMarker.position,
    icon: BitmapDescriptor.fromBytes(uint8List),
    draggable: widgetMarker.draggable,
    infoWindow: widgetMarker.infoWindow,
    rotation: widgetMarker.rotation,
    visible: widgetMarker.visible,
    zIndex: widgetMarker.zIndex,
    onDragStart: widgetMarker.onDragStart,
    onDragEnd: widgetMarker.onDragEnd,
    onDrag: widgetMarker.onDrag,
  );
}


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => onBuildCompleted());
  }

  Future<void> onBuildCompleted() async {
    /// Skip when there's no change in widgetMarkers.
    if (lastMarkers == widget.widgetMarkers) {
      return;
    }
    lastMarkers = widget.widgetMarkers;
    final markers =
        await Future.wait(globalKeys.map((key) => _convertToMarker(key)));
    widget.onMarkerGenerated.call(markers);
  }

  @override
  Widget build(BuildContext context) {
    globalKeys = [];
return Transform.translate(
  offset: Offset(
    0,
    -MediaQuery.of(context).size.height,
  ),
  child: Stack(
    children: widget.widgetMarkers.map(
      (widgetMarker) {
        final key = GlobalKey();
        globalKeys.add(key);
        return RepaintBoundary(
          key: key,
          child: widgetMarker.widget,
        );
      },
    ).toList(),
  ),
);

  }
}
