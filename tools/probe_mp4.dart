import 'dart:io';
import 'dart:typed_data';

// Diagnostic for local MP4 timing boxes; never writes the inspected file.
void main(List<String> args) {
  final data = File(args.single).readAsBytesSync();
  final view = ByteData.sublistView(data);
  void boxes(int start, int end, String path) {
    var at = start;
    while (at + 8 <= end) {
      var size = view.getUint32(at);
      final type = String.fromCharCodes(data.sublist(at + 4, at + 8));
      var header = 8;
      if (size == 1) {
        size = view.getUint64(at + 8);
        header = 16;
      }
      if (size == 0) size = end - at;
      if (size < header || at + size > end) return;
      final body = at + header;
      final name = '$path/$type';
      if (['moov', 'trak', 'mdia', 'minf', 'stbl', 'edts'].contains(type)) {
        boxes(body, at + size, name);
      } else if (['mvhd', 'mdhd'].contains(type)) {
        final version = view.getUint8(body);
        final scaleOffset = version == 1 ? 20 : 12;
        final scale = view.getUint32(body + scaleOffset);
        final ticks = version == 1
            ? view.getUint64(body + scaleOffset + 4)
            : view.getUint32(body + scaleOffset + 4);
        // ignore: avoid_print
        print('$name scale=$scale ticks=$ticks seconds=${ticks / scale}');
      } else if (type == 'stts') {
        final count = view.getUint32(body + 4);
        var ticks = 0, samples = 0;
        for (var i = 0; i < count; i++) {
          final n = view.getUint32(body + 8 + i * 8);
          final delta = view.getUint32(body + 12 + i * 8);
          ticks += n * delta;
          samples += n;
        }
        // ignore: avoid_print
        print('$name entries=$count samples=$samples ticks=$ticks');
      } else if (type == 'elst') {
        final version = view.getUint8(body);
        final count = view.getUint32(body + 4);
        // ignore: avoid_print
        print('$name version=$version entries=$count');
        var row = body + 8;
        for (var i = 0; i < count; i++) {
          final duration =
              version == 1 ? view.getUint64(row) : view.getUint32(row);
          final time =
              version == 1 ? view.getInt64(row + 8) : view.getInt32(row + 4);
          // ignore: avoid_print
          print('  duration=$duration mediaTime=$time');
          row += version == 1 ? 20 : 12;
        }
      }
      at += size;
    }
  }

  boxes(0, data.length, '');
}
