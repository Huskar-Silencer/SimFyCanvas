import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class DraftStore {
  /// Newest draft first, followed by recovery copies.
  Future<List<String>> readCandidates();

  Future<void> write(String source);
}

/// Stores the recovery draft in the platform's application-support folder.
///
/// Writes use a temporary file and retain the previous valid file as a backup,
/// so an interrupted write cannot destroy the only recovery copy.
class FileDraftStore implements DraftStore {
  FileDraftStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const fileName = 'recovery-draft.json';

  final Future<Directory> Function() _directory;

  @override
  Future<List<String>> readCandidates() async {
    final files = await _files();
    final sources = <String>[];
    for (final file in [files.primary, files.backup]) {
      if (await file.exists()) {
        sources.add(await file.readAsString());
      }
    }
    return sources;
  }

  @override
  Future<void> write(String source) async {
    final files = await _files();
    await files.directory.create(recursive: true);
    await files.temporary.writeAsString(source, flush: true);

    if (await files.backup.exists()) {
      await files.backup.delete();
    }
    if (await files.primary.exists()) {
      await files.primary.rename(files.backup.path);
    }
    try {
      await files.temporary.rename(files.primary.path);
    } catch (_) {
      if (!await files.primary.exists() && await files.backup.exists()) {
        await files.backup.rename(files.primary.path);
      }
      rethrow;
    }
  }

  Future<_DraftFiles> _files() async {
    final directory = await _directory();
    final separator = Platform.pathSeparator;
    final path = '${directory.path}$separator$fileName';
    return _DraftFiles(
      directory,
      File(path),
      File('$path.backup'),
      File('$path.tmp'),
    );
  }
}

class _DraftFiles {
  const _DraftFiles(this.directory, this.primary, this.backup, this.temporary);

  final Directory directory;
  final File primary;
  final File backup;
  final File temporary;
}
