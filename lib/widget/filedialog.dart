import 'dart:io';

import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum FileDialogTarget { FILE, DIRECTORY }

class FileDialogItem {
  FileDialogItem(this.fsEntity, [bool selected = false])
      : selected = selected,
        color = Colors.white;
  bool selected = false;
  Color color;
  FileSystemEntity fsEntity;
}

class FileDialog extends StatefulWidget {
  final Function(FileSystemEntity) onOpen;
  final FileDialogTarget target;
  final String title;
  FileDialog({Key key, this.onOpen, this.title, FileDialogTarget target})
      : target = (target == null) ? FileDialogTarget.FILE : target,
        super(key: key);
  @override
  _FileDialogState createState() => _FileDialogState();
}

class _FileDialogState extends State<FileDialog>
    with StateWithLocalization<FileDialog> {
  List<Widget> _widgets = [];
  FileSystemEntity _lastSelected;

  void _action(FileSystemEntity fsEntity) {
    _deselectOthers(fsEntity);

    State state = keys[fsEntity].currentState;
    if (fsEntity is Directory) {
      if (state is _FileDialogUpRowState) {
        stepInto(fsEntity.parent.path);
      } else if (state is _FileDialogRowState) {
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
        State state = keys[fs].currentState;
        if (state is _FileDialogUpRowState) {
          state.deselect();
        } else if (state is _FileDialogRowState) {
          state.deselect();
        }
      }
    });
  }

  Directory _lastDirectory = Directory.current;

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
    if (curDir.parent != null)
      items.add(FileDialogUpRow(
          key: _getNewKey<_FileDialogUpRowState>(curDir),
          fsEntity: curDir,
          onAction: _action,
          isSelectable: widget.target == FileDialogTarget.FILE,
          onSelect: _select));
    for (var i = 0; i < fsItems.length; i++) {
      items.add(FileDialogRow(
          key: _getNewKey<_FileDialogRowState>(fsItems[i]),
          fsEntity: fsItems[i],
          onAction: _action,
          isSelectable: widget.target == FileDialogTarget.FILE,
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
    return keys[fsEntity];
  }

  void _onPressed() {
    if (widget.target == FileDialogTarget.DIRECTORY && _lastDirectory != null) {
      print("Open '${_lastDirectory.path}' directory");
      if (widget.onOpen != null) {
        widget.onOpen(_lastDirectory);
      }
    } else if (widget.target == FileDialogTarget.FILE &&
        _lastSelected != null) {
      print("Open '${_lastSelected.path}' file");
      if (widget.onOpen != null) {
        widget.onOpen(_lastSelected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 10),
        Text(widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        SizedBox(height: 15),
        Expanded(
          child: Card(
            child: ListView(
              children: _widgets,
            ),
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            MaterialButton(
              child: Text(tr('select')),
              onPressed: _onPressed,
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
  final Function(FileSystemEntity) onAction;
  final Function(FileSystemEntity) onSelect;
  final bool isSelectable;
  FileDialogRow(
      {Key key, this.fsEntity, this.onAction, this.onSelect, bool isSelectable})
      : isSelectable = (isSelectable == null) ? true : isSelectable,
        super(key: key);
  @override
  _FileDialogRowState createState() => _FileDialogRowState();
}

class _FileDialogRowState extends State<FileDialogRow> {
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
    if (path.startsWith(Platform.isWindows ? '\\' : '/'))
      path = path.substring(1);
    super.initState();
  }

  void _handleMouseEnter(PointerEnterEvent event) => setState(() {
        hovering = true;
      });
  void _handleMouseExit(PointerExitEvent event) => setState(() {
        hovering = false;
      });

  void select() {
    if (!selected)
      setState(() {
        selected = !selected;
      });
  }

  void deselect() {
    if (selected)
      setState(() {
        selected = !selected;
      });
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
                  if (widget.onSelect != null) widget.onSelect(widget.fsEntity);
                  select();
                }
              : null,
          onDoubleTap: () {
            if (widget.onAction != null) widget.onAction(widget.fsEntity);
          },
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            SizedBox(width: 5),
            Icon(
              (widget.fsEntity is Directory) ? Icons.folder : Icons.web_asset,
              color: (widget.fsEntity is Directory)
                  ? Colors.orange.shade200
                  : Colors.grey.shade400,
              size: 25,
            ),
            SizedBox(width: 5),
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
  final Function(FileSystemEntity) onAction;
  final Function(FileSystemEntity) onSelect;
  final bool isSelectable;
  FileDialogUpRow(
      {Key key, this.fsEntity, this.onAction, this.onSelect, bool isSelectable})
      : isSelectable = (isSelectable == null) ? true : isSelectable,
        super(key: key);
  @override
  _FileDialogUpRowState createState() => _FileDialogUpRowState();
}

class _FileDialogUpRowState extends State<FileDialogUpRow> {
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
    if (!selected)
      setState(() {
        selected = !selected;
      });
  }

  void deselect() {
    if (selected)
      setState(() {
        selected = !selected;
      });
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
                  if (widget.onSelect != null) widget.onSelect(widget.fsEntity);
                  select();
                }
              : null,
          onDoubleTap: () {
            if (widget.onAction != null) widget.onAction(widget.fsEntity);
          },
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            SizedBox(width: 5),
            Icon(
              Icons.arrow_upward,
              color: Colors.grey.shade600,
              size: 25,
            ),
            SizedBox(width: 5),
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
