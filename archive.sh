#!/bin/sh
# SC1007: Allow space after variable=
# Allow local at it is supported on most shells
# shellcheck disable=SC1007,SC3043

set -o nounset

main () {
    local main_py='main.py'
    local version_py="$main_py"
    local version_pattern='^\(VERSION\|__version__\) = .*'
    local name description original_version
    local os_type
    set_os_type || return
    init || return
    update_version
    build
    restore_version
    copy_scripts
    copy_profiles
    archive
    test_help
}

set_os_type () {
    local sys
    if ! sys=$(uname -s); then
        printf >&2 "error: unable to determine OS type\n"
        return 1
    fi
    case $sys in
    Linux)
        os_type=linux
        ;;
    MINGW*|CYGWIN*)
        os_type=windows
        ;;
    *)
        printf >&2 "error: unknown OS type: %s\n" "$sys"
        return 1
        ;;
    esac
}

init () {
    cd "$(git rev-parse --show-toplevel)" || exit
    name=$(basename "$PWD")
    if ! test -d ".venv"; then
        printf "create .venv\n"
        python -m venv .venv || return
    fi
    if ! test "${VIRTUAL_ENV-}"; then
        printf "activate venv\n"
        # shellcheck disable=SC1091 # not following
        case $os_type in
            windows)
                . .venv/Scripts/activate || return
                ;;
            *)
                . .venv/bin/activate || return
                ;;
        esac
    fi
    printf "install packages\n"
    pip install -q --disable-pip-version-check -r requirements.txt || return
}

update_version () {
    trap clean_up INT TERM
    description=$(git describe --always) || exit
    description=${description#v}
    original_version=$(grep "$version_pattern" "$version_py") || exit
    sed -bi -e "s/$version_pattern/\1 = \"$description\"/" "$version_py" || exit
}

build () {
    pyinstaller "$main_py" -y --noupx --contents-directory dependencies --name "$name"
}

restore_version () {
    trap - INT TERM
    sed -bi -e "s/$version_pattern/$original_version/" "$version_py"
}

copy_scripts () {
    cp -r scripts/ "dist/$name/"
}

copy_profiles () {
    cp profiles.example.toml "dist/$name/"
}

archive () {
    "archive_$os_type"
}

archive_linux () {
    local archive_name="$name-$description-linux"
    (
        cd dist || return
        (
            set +o noglob
            rm -f "$name"-*.tgz
        )
        printf "creating archive: %s\n" "$archive_name.tgz"
        tar -zcf "$archive_name.tgz" "$name/" || return
    ) || return
}

archive_windows () {
    local exe7z
    local archive_name="$name-$description-windows"
    exe7z=$(find_7z) || return
    printf "using %s\n" "$exe7z"
    printf "creating archive: %s\n" "$archive_name.7z"
    (
        cd dist || return
        (
            set +o noglob
            rm -f "$name"-*.7z
        )
        "$exe7z" a -mx9 "$archive_name.7z" "$name/" || return
    ) || return
}

find_7z () {
    local exe_from_7zip="C:/Program Files/7-Zip/7z.exe"
    local exe_from_jai="C:/Users/$USERNAME/AppData/Local/Programs/jai/7za.exe"
    if test -x "$exe_from_7zip"
    then
        printf "%s" "$exe_from_7zip"
    elif test -x "$exe_from_jai"
    then
        printf "%s" "$exe_from_jai"
    else
        printf >&2 "warning: no 7-Zip excutable available, skipping archive, see files to be archived in %s\n" "dist/$name/"
        return 1
    fi
    return 0
}

test_help () {
    case $os_type in
        linux)
            "./dist/$name/$name" -h
            ;;
        windows)
            "./dist/$name/$name.exe" -h
            ;;
    esac
}

clean_up () {
    restore_version
    exit 1
}

main "$@"
