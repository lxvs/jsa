#!/bin/sh
set -o nounset

main () {
    local main_py='main.py'
    local version_py="$main_py"
    local version_pattern='^\(VERSION\|__version__\) = .*'
    local name description original_version
    init || return
    update_version
    build
    restore_version
    print_pdf
    copy_scripts
    copy_profiles
    archive
    test_help
}

init () {
    cd `git rev-parse --show-toplevel` || exit
    name=`basename "$PWD"`
    if ! test "${VIRTUAL_ENV-}"; then
        printf "activate venv\n"
        . ./.venv/Scripts/activate || return
    fi
    printf "install packages\n"
    pip install -q --disable-pip-version-check -r requirements.txt || return
}

update_version () {
    trap clean_up INT TERM
    description=`git describe --always` || exit
    description=${description#v}
    original_version=`grep "$version_pattern" "$version_py"` || exit
    sed -bi -e "s/$version_pattern/\1 = \"$description\"/" "$version_py" || exit
}

build () {
    pyinstaller "$main_py" -y --noupx --contents-directory dependencies --name "$name"
}

restore_version () {
    trap - INT TERM
    sed -bi -e "s/$version_pattern/$original_version/" "$version_py"
}

print_pdf () {
    asciidoctor-pdf ./*.adoc -D "dist/$name/"
}

copy_scripts () {
    cp -r scripts/ "dist/$name/"
}

copy_profiles () {
    cp profiles.example.toml "dist/$name/"
}

archive () {
    case ${OSTYPE-} in
    linux-gnu)
        archive_linux
        ;;
    msys)
        archive_windows
        ;;
    *)
        printf >&2 "error: unknown OS type: %s\n" "${OSTYPE-'(Undefined)'}"
        ;;
    esac
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
    exe7z=`find_7z` || return
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
    "./dist/$name/$name.exe" -h
}

clean_up () {
    restore_version
    exit 1
}

main "$@"
