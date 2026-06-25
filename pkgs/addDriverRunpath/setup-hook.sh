addDriverRunpath() {
    local forceRpath=

    while [ $# -gt 0 ]; do
        case "$1" in
            --) shift; break;;
            --force-rpath) shift; forceRpath=1;;
            --*)
                echo "addDriverRunpath: ERROR: Invalid command line" \
                     "argument: $1" >&2
                return 1;;
            *) break;;
        esac
    done

    for file in "$@"; do
        if ! isELF "$file"; then continue; fi
        local origRpath="$(patchelf --print-rpath "$file")"
        patchelf --set-rpath "@driverLink@/lib:$origRpath" ${forceRpath:+--force-rpath} "$file"
    done
}
