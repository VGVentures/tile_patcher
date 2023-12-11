import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TilesetPatcher(),
    );
  }
}

class _Selection {
  const _Selection({
    required this.path,
    required this.image,
    required this.patch,
  });

  final String path;
  final ui.Image image;
  final ui.Image patch;
}

class TilesetPatcher extends StatefulWidget {
  const TilesetPatcher({super.key});

  @override
  State<TilesetPatcher> createState() => _TilesetPatcherState();
}

class _TilesetPatcherState extends State<TilesetPatcher> {
  _Selection? _selection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selection == null
          ? _SelectView(
              onSelect: (_Selection selection) {
                setState(() {
                  _selection = selection;
                });
              },
            )
          : _PreviewView(
              selection: _selection!,
              onCancel: () {
                setState(() {
                  _selection = null;
                });
              },
            ),
    );
  }
}

class _SelectView extends StatelessWidget {
  const _SelectView({
    required this.onSelect,
  });

  final void Function(_Selection) onSelect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          const typeGroup = XTypeGroup(
            label: 'images',
            extensions: <String>['jpg', 'png'],
          );
          final file =
              await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

          if (file != null) {
            final bytes = await file.readAsBytes();
            final image = await decodeImageFromList(bytes);

            final selection = _Selection(
              path: file.path,
              image: image,
              patch: image,
            );

            onSelect(selection);
          }
        },
        child: const Text('Load image'),
      ),
    );
  }
}

class _PreviewView extends StatefulWidget {
  const _PreviewView({
    required this.selection,
    required this.onCancel,
  });

  final _Selection selection;
  final VoidCallback onCancel;

  @override
  State<_PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<_PreviewView> {
  late _Selection _selection = widget.selection;

  final _gridsizeController = TextEditingController(text: '0');
  final _gridHeightController = TextEditingController(text: '0');
  final _spaceController = TextEditingController(text: '0');

  bool _square = true;
  bool _bleedBottom = true;
  bool _bleedRight = true;

  Future<void> _save() async {
    final imageBytes = await _selection.patch.toByteData(
      format: ui.ImageByteFormat.png,
    );

    File(_selection.path).writeAsBytesSync(imageBytes!.buffer.asUint8List());
  }

  Future<void> _update() async {
    final gridWidth = double.parse(_gridsizeController.text);
    final gridHeight = _square
        ? double.parse(_gridsizeController.text)
        : double.parse(_gridHeightController.text);
    final space = int.parse(_spaceController.text);
    final newGridWidth = gridWidth + space;
    final newGridHeight = gridHeight + space;

    final image = widget.selection.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = Paint();

    final verticalTiles = (image.height / gridHeight).ceil();
    final horizontalTiles = (image.width / gridWidth).ceil();
    for (double y = 0; y < verticalTiles; y++) {
      for (double x = 0; x < horizontalTiles; x++) {
        final src = Rect.fromLTWH(
          x * gridWidth,
          y * gridHeight,
          gridWidth,
          gridHeight,
        );

        final dst = Rect.fromLTWH(
          x * newGridWidth,
          y * newGridHeight,
          gridWidth,
          gridHeight,
        );

        canvas.drawImageRect(
          image,
          src,
          dst,
          paint,
        );

        if (_bleedBottom) {
          // Bottom bleeder
          final bottomPatcherSrc = Rect.fromLTWH(
            x * gridWidth,
            y * gridHeight + gridHeight - 1,
            gridWidth,
            space.toDouble(),
          );

          final bottomPatcherDst = Rect.fromLTWH(
            x * newGridWidth,
            y * newGridHeight + gridHeight,
            newGridWidth,
            space.toDouble(),
          );

          canvas.drawImageRect(
            image,
            bottomPatcherSrc,
            bottomPatcherDst,
            paint,
          );
        }

        if (_bleedRight) {
          // Right bleeder
          final rightPatcherSrc = Rect.fromLTWH(
            x * gridWidth + gridWidth - 1,
            y * gridHeight,
            space.toDouble(),
            gridHeight,
          );

          final rightPatcherDst = Rect.fromLTWH(
            x * newGridWidth + gridWidth,
            y * newGridHeight,
            space.toDouble(),
            newGridHeight,
          );

          canvas.drawImageRect(
            image,
            rightPatcherSrc,
            rightPatcherDst,
            paint,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final newImage = await picture.toImage(
      (horizontalTiles * newGridWidth).toInt(),
      (verticalTiles * newGridHeight).toInt(),
    );

    setState(() {
      _selection = _Selection(
        path: widget.selection.path,
        image: widget.selection.image,
        patch: newImage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _update,
                child: const Text('Update'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: widget.onCancel,
                child: const Text('Close'),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Square'),
              Switch(
                value: _square,
                onChanged: (value) {
                  setState(() {
                    _square = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              const Text('Patch bottom'),
              Switch(
                value: _bleedBottom,
                onChanged: (value) {
                  setState(() {
                    _bleedBottom = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              const Text('Patch right'),
              Switch(
                value: _bleedRight,
                onChanged: (value) {
                  setState(() {
                    _bleedRight = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _spaceController,
                  decoration: const InputDecoration(
                    label: Text('Spacing'),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _gridsizeController,
                  decoration: InputDecoration(
                    label: Text(_square ? 'Grid Size' : 'Grid Width'),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!_square) ...[
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _gridHeightController,
                    decoration: const InputDecoration(
                      label: Text('Grid Height'),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 8),
          const VerticalDivider(),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: RawImage(image: _selection.image)),
                      Text(
                        'Original: ${_selection.image.width}x${_selection.image.height}',
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: RawImage(image: _selection.patch),
                      ),
                      Text(
                        'Patch: ${_selection.patch.width}x${_selection.patch.height}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
