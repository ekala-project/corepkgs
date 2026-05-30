source $stdenv/setup

eval "$preInstall"

args=

target=$out
if [ -n "${dir:-}" ]; then
    target=$out/$dir/$name
    mkdir -p $out/$dir
fi

substituteAll "$src" "$target"

if [ -n "${isExecutable:-}" ]; then
    chmod +x "$target"
fi

eval "$postInstall"
