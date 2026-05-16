#!/usr/bin/env bash
# Stop-event reminder: emit the JMVG agent closing checklist before the
# session ends so the agent doesn't forget to close the loop on its queue
# and memory file. Closes the "agents forget to update memory" gap.
#
# Triggered by: Stop event.

cat <<'EOF' >&2
[reminder] Before ending the session, close the loop:
  1. Tick your queue item in jmvg-ops/queues/<YourAgent>.md (move it to ## Done)
  2. Append a durable one-liner to jmvg-ops/<YourAgent>Memory.md
     (Current State delta + commit SHA(s) + verification note)
  3. Commit + push jmvg-ops on the working branch
  4. If any specialist hand-off is needed, append to the target's queue too

If the task is partial, leave the queue item in ## Active with a "blocked on X"
note instead of ticking it — don't lose state by leaving it half-claimed.
EOF

exit 0
