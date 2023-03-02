import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class EditorRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EditorRouter();
  }
}

class _EditorRouter extends State<EditorRouter> {
  quill.QuillController _controller = quill.QuillController.basic();

  @override
  Widget build(BuildContext context) {
    // TODO embed: image、video、bitcoin
    // TODO embed input: image、video、bitcoin
    // TODO relation input: events、users、emoji

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Column(
          children: [
            Expanded(
                child: quill.QuillEditor.basic(
              controller: _controller,
              readOnly: false,
              embedBuilders: FlutterQuillEmbeds.builders(),
            )),
            quill.QuillToolbar(
              toolbarIconAlignment: WrapAlignment.start,
              toolbarIconCrossAlignment: WrapCrossAlignment.start,
              children: [
                quill.QuillIconButton(
                  onPressed: pickImage,
                  icon: Icon(Icons.image),
                ),
                quill.QuillIconButton(
                  onPressed: () {},
                  icon: Icon(Icons.camera),
                ),
                quill.QuillIconButton(
                  onPressed: () {},
                  icon: Icon(Icons.currency_bitcoin),
                ),
                quill.QuillIconButton(
                  onPressed: documentSave,
                  icon: Icon(Icons.tag_faces),
                ),
                Expanded(child: Container()),
              ],
              // embedButtons: FlutterQuillEmbeds.buttons(),
            ),
          ],
        ),
      ),
    );
  }

  void pickImage() {
    _imageSubmitted(
        "https://up.enterdesk.com/edpic/0c/ef/a0/0cefa0f17b83255217eddc20b15395f9.jpg");
  }

  void _imageSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(
          index, length, quill.BlockEmbed.image(value), null);
    }
  }

  void documentSave() {
    print(_controller.document.toDelta().toJson());
  }
}
