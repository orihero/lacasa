#!/bin/bash
# Hot-reload the running Flutter app whenever a .dart file under
# apps/mobile_flutter/ is written or edited.
#
# The handle is `flutter run --pid-file`, which documents SIGUSR1 as hot
# reload and SIGUSR2 as hot restart. That is used here rather than piping
# "r" into the process's stdin, because a `flutter run` started from a
# terminal owns that terminal's stdin and nothing else can write to it.
#
# Launch the app so this hook has something to signal:
#
#   cd apps/mobile_flutter
#   flutter run --pid-file ~/.claude/lacasa-flutter/run.pid
#
# Every branch below is a silent no-op: no pid file, a stale pid file, a
# dead process, or a file outside the Flutter app must never fail a tool
# call or print anything into the transcript.
#
# NOT covered — these need a full relaunch, not a reload:
#   - pubspec.yaml changes (new asset/font declarations, dependencies)
#   - anything under assets/
#   - .arb changes, which need `flutter gen-l10n` before the generated
#     Dart the app actually imports is reloadable
set -u

PID_FILE="$HOME/.claude/lacasa-flutter/run.pid"

file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)

case "$file" in
  */apps/mobile_flutter/*.dart) ;;
  *) exit 0 ;;
esac

[ -s "$PID_FILE" ] || exit 0
pid=$(cat "$PID_FILE" 2>/dev/null) || exit 0
[ -n "$pid" ] || exit 0

# kill -0 probes for existence without signalling, so a stale pid file left
# behind by a crashed run is distinguished from a live one.
kill -0 "$pid" 2>/dev/null || exit 0
kill -USR1 "$pid" 2>/dev/null || exit 0

exit 0
