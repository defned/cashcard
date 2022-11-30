import 'dart:io';

import 'package:cashcard/util/extensions.dart';
import 'package:cashcard/util/logging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum FileDialogTarget { tFILE, tDIRECTORY }

class FileDialogItem {
  FileDialogItem(this.fsEntity, {this.selected = false}) : color = Colors.white;
  bool selected = false;
  Color color;
  FileSystemEntity fsEntity;
}

class FileDialog extends StatefulWidget {
  final Function(FileSystemEntity)? onOpen;
  final FileDialogTarget target;
  final String title;
  const FileDialog(
      {super.key,
      required this.title,
      this.onOpen,
      this.target = FileDialogTarget.tFILE});
  @override
  FileDialogState createState() => FileDialogState();
}

class FileDialogState extends State<FileDialog>
    with StateWithLocalization<FileDialog> {
  List<Widget> _widgets = [];
  FileSystemEntity? _lastSelected;

  void _action(FileSystemEntity fsEntity) {
    _deselectOthers(fsEntity);

    State state = keys[fsEntity]!.currentState!;
    if (fsEntity is Directory) {
      if (state is FileDialogUpRowState) {
        stepInto(fsEntity.parent.path);
      } else if (state is FileDialogRowState) {
        stepInto(fsEntity.path);
      }
    }
  }

  void _select(FileSystemEntity fsEntity) {
    _deselectOthers(fsEntity);
    setState(() {
      _lastSelected = (fsEntity is Directory) ? null : fsEntity;
    });
  }

  void _deselectOthers(FileSystemEntity fsEntity) {
    keys.forEach((fs, key) {
      if (fs != fsEntity) {
        State state = keys[fs]!.currentState!;
        if (state is FileDialogUpRowState) {
          state.deselect();
        } else if (state is FileDialogRowState) {
          state.deselect();
        }
      }
    });
  }

  Directory? _lastDirectory = Directory.current;

  void stepInto(String path) {
    Directory curDir = Directory(Directory(path).absolute.path);
    _lastDirectory = curDir;

    List<FileSystemEntity> fsItems = curDir.listSync();
    fsItems.sort((a, b) {
      if (a is Directory && b is! Directory) {
        return -1;
      } else if (a is! Directory && b is Directory) {
        return 1;
      }
      return a.path.compareTo(b.path);
    });
    List<Widget> items = [];
    items.add(FileDialogUpRow(
        key: _getNewKey<FileDialogUpRowState>(curDir),
        fsEntity: curDir,
        onAction: _action,
        isSelectable: widget.target == FileDialogTarget.tFILE,
        onSelect: _select));
    for (var i = 0; i < fsItems.length; i++) {
      items.add(FileDialogRow(
          key: _getNewKey<FileDialogRowState>(fsItems[i]),
          fsEntity: fsItems[i],
          onAction: _action,
          isSelectable: widget.target == FileDialogTarget.tFILE,
          onSelect: _select));
    }

    setState(() {
      _widgets = items;
    });
  }

  @override
  void initState() {
    stepInto(Directory.current.path);
    super.initState();
  }

  Map<FileSystemEntity, GlobalKey> keys = {};
  GlobalKey _getNewKey<T extends State>(FileSystemEntity fsEntity) {
    keys[fsEntity] = GlobalKey<T>();
    return keys[fsEntity]!;
  }

  void _onPressed() {
    if (widget.target == FileDialogTarget.tDIRECTORY &&
        _lastDirectory != null) {
      log("Open '${_lastDirectory!.path}' directory");
      widget.onOpen?.call(_lastDirectory!);
    } else if (widget.target == FileDialogTarget.tFILE &&
        _lastSelected != null) {
      log("Open '${_lastSelected!.path}' file");
      widget.onOpen?.call(_lastSelected!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        Text(widget.title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyText1!.color)),
        const SizedBox(height: 15),
        Expanded(
          child: Card(
            child: ListView(
              children: _widgets,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            MaterialButton(
              onPressed: _onPressed,
              child: Text(tr('select')),
            ),
            MaterialButton(
              child: Text(tr('close')),
              onPressed: () {
                Navigator.maybePop(context);
              },
            )
          ],
        ),
      ],
    );
  }
}

class FileDialogRow extends StatefulWidget {
  final FileSystemEntity fsEntity;
  final Function(FileSystemEntity)? onAction;
  final Function(FileSystemEntity)? onSelect;
  final bool isSelectable;
  const FileDialogRow(
      {super.key,
      required this.fsEntity,
      this.onAction,
      this.onSelect,
      this.isSelectable = true});
  @override
  FileDialogRowState createState() => FileDialogRowState();
}

class FileDialogRowState extends State<FileDialogRow> {
  String path = '';
  bool hovering = false;
  bool enabled = true;
  bool selected = false;
  Color backgroundColor = Colors.transparent;
  Color selectedColor = Colors.blue.shade400;
  Color hoveredColor = Colors.blue.shade100;

  @override
  void initState() {
    String parent = widget.fsEntity.parent.path;
    path = widget.fsEntity.path;
    path = path.replaceFirst(parent, '');
    if (path.startsWith(Platform.isWindows ? '\\' : '/')) {
      path = path.substring(1);
    }
    super.initState();
  }

  void _handleMouseEnter(PointerEnterEvent event) => setState(() {
        hovering = true;
      });
  void _handleMouseExit(PointerExitEvent event) => setState(() {
        hovering = false;
      });

  void select() {
    if (!selected) {
      setState(() {
        selected = !selected;
      });
    }
  }

  void deselect() {
    if (selected) {
      setState(() {
        selected = !selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // duration: Duration(milliseconds: 100),
      color: selected
          ? selectedColor
          : (hovering ? hoveredColor : backgroundColor),
      child: MouseRegion(
        onEnter: enabled ? _handleMouseEnter : null,
        onExit: enabled ? _handleMouseExit : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.isSelectable
              ? () {
                  widget.onSelect?.call(widget.fsEntity);
                  select();
                }
              : null,
          onDoubleTap: () {
            widget.onAction?.call(widget.fsEntity);
          },
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            const SizedBox(width: 5),
            Icon(
              (widget.fsEntity is Directory) ? Icons.folder : Icons.web_asset,
              color: (widget.fsEntity is Directory)
                  ? Colors.orange.shade200
                  : Colors.grey.shade400,
              size: 25,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                path,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ]),
        ),
      ),
    );
  }
}

class FileDialogUpRow extends StatefulWidget {
  final FileSystemEntity fsEntity;
  final Function(FileSystemEntity)? onAction;
  final Function(FileSystemEntity)? onSelect;
  final bool isSelectable;
  const FileDialogUpRow(
      {super.key,
      required this.fsEntity,
      this.onAction,
      this.onSelect,
      this.isSelectable = true});
  @override
  FileDialogUpRowState createState() => FileDialogUpRowState();
}

class FileDialogUpRowState extends State<FileDialogUpRow> {
  String path = '..';
  bool hovering = false;
  bool enabled = true;
  bool selected = false;
  Color backgroundColor = Colors.transparent;
  Color selectedColor = Colors.blue.shade400;
  Color hoveredColor = Colors.blue.shade100;

  @override
  void initState() {
    path = widget.fsEntity.absolute.uri.normalizePath().path;
    if (path.startsWith('/')) path = path.substring(1);
    super.initState();
  }

  void _handleMouseEnter(PointerEnterEvent event) => setState(() {
        hovering = true;
      });
  void _handleMouseExit(PointerExitEvent event) => setState(() {
        hovering = false;
      });

  void select() {
    if (!selected) {
      setState(() {
        selected = !selected;
      });
    }
  }

  void deselect() {
    if (selected) {
      setState(() {
        selected = !selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // duration: Duration(milliseconds: 100),
      color: widget.isSelectable
          ? (selected
              ? selectedColor
              : (hovering ? hoveredColor : backgroundColor))
          : null,
      child: MouseRegion(
        onEnter: enabled ? _handleMouseEnter : null,
        onExit: enabled ? _handleMouseExit : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.isSelectable
              ? () {
                  widget.onSelect?.call(widget.fsEntity);
                  select();
                }
              : null,
          onDoubleTap: () {
            widget.onAction?.call(widget.fsEntity);
          },
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            const SizedBox(width: 5),
            Icon(
              Icons.arrow_upward,
              color: Colors.grey.shade600,
              size: 25,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                path,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ]),
        ),
      ),
    );
  }
}
