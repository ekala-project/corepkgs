# Read the [Install] section of a systemd unit file and print the
# dependency links `systemctl enable` would create, one per line:
#
#   instance <name>      DefaultInstance= value (only if set)
#   wants <target>       from WantedBy=
#   requires <target>    from RequiredBy=
#   upholds <target>     from UpheldBy=
#
# Follows systemd's parsing rules: leading/trailing whitespace is ignored,
# lines starting with '#' or ';' are comments, a value may list several
# space-separated targets, and an empty assignment resets the list.

function trim(s) {
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}

{
  line = trim($0)
}

line == "" || line ~ /^[#;]/ { next }

line ~ /^\[/ {
  section = line
  next
}

section != "[Install]" { next }

{
  eq = index(line, "=")
  if (eq == 0) next
  key = trim(substr(line, 1, eq - 1))
  value = trim(substr(line, eq + 1))

  if (key == "DefaultInstance") {
    instance = value
    next
  }
  if (key == "WantedBy") kind = "wants"
  else if (key == "RequiredBy") kind = "requires"
  else if (key == "UpheldBy") kind = "upholds"
  else next

  if (value == "") {
    targets[kind] = ""
    next
  }
  targets[kind] = targets[kind] " " value
}

END {
  if (instance != "") print "instance", instance
  split("wants requires upholds", kinds, " ")
  for (k = 1; k <= 3; k++) {
    n = split(targets[kinds[k]], list, /[[:space:]]+/)
    for (i = 1; i <= n; i++)
      if (list[i] != "") print kinds[k], list[i]
  }
}
