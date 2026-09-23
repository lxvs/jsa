#!/bin/sh
# SC1007: Allow space after variable=
# Allow local at it is supported on most shells
# shellcheck disable=SC1007,SC3043

set -o nounset

set_os_type ()
{
    local sys
    if ! sys=$(uname -s); then
        printf >&2 "error: unable to determine OS type\n"
        return 1
    fi
    case $sys in
    MINGW*|CYGWIN*|MSYS*)
        os_type=windows
        ;;
    Linux)
        os_type=linux
        ;;
    *)
        printf >&2 "warning: unknown OS type: %s; assuming unix-like\n" "$sys"
        os_type=linux
        ;;
    esac
}

init ()
{
    cd "$(git rev-parse --show-toplevel)" || exit
    name=$(basename "$PWD")
    test -f "requirements.txt" || return 0
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

update_version ()
{
    test -f "$version_py" || return
    trap clean_up INT TERM
    description=$(git describe --always) || exit
    description=${description#v}
    original_version=$(grep "$version_pattern" "$version_py") || exit
    sed -bi -e "s/$version_pattern/\1 = \"$description\"/" "$version_py" || exit
}

build ()
{
    local opts="--noupx --contents-directory dependencies"
    test -f "docs/favicon.ico" && opts="$opts --icon docs/favicon.ico"
    printf 'pyinstaller "%s" --name "%s" %s\n' "$main_py" "$name" "$opts"
    pyinstaller --log-level WARN -y "$main_py" --name "$name" $opts
}

restore_version ()
{
    test -f "$version_py" || return
    trap - INT TERM
    sed -bi -e "s/$version_pattern/$original_version/" "$version_py"
}

copy_scripts ()
{
    cp -r scripts/ "dist/$name/"
}

copy_profiles ()
{
    cp profiles.example.toml "dist/$name/"
}

copy_docs ()
{
    git clean -fx -- docs/
    find docs/ -name '*.md' -exec cp --parents -t "dist/$name/" {} +
}

find_7z ()
{
    local exe_from_7zip exe_from_jai
    if type 7za >/dev/null 2>&1; then
        printf "7za"
    else
        case $os_type in
            windows)
                exe_from_7zip="C:/Program Files/7-Zip/7z.exe"
                exe_from_jai="$USERPROFILE/AppData/Local/Programs/jai/7za.exe"
                if test -x "$exe_from_7zip"; then
                    printf "%s" "$exe_from_7zip"
                elif test -x "$exe_from_jai"; then
                    printf "%s" "$exe_from_jai"
                else
                    printf >&2 "warning: no 7-Zip excutable available, skipping archive, see files to be archived in %s\n" "dist/"
                    return 1
                fi
                ;;
            linux)
                printf >&2 "warning: no 7-Zip excutable available, skipping archive, see files to be archived in %s\n" "dist/"
                return 1
                ;;
            *)
                printf >&2 "warning: unknown OS type: %s; assuming unix-like\n" "$os_type"
                printf >&2 "warning: no 7-Zip excutable available, skipping archive, see files to be archived in %s\n" "dist/"
                return 1
                ;;
        esac
    fi
    return 0
}

archive_linux ()
{
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

archive_windows ()
{
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

archive ()
{
    "archive_$os_type"
}

test_ver_and_help ()
{
    case $os_type in
        windows)
            "./dist/$name/$name.exe" -V
            "./dist/$name/$name.exe" -h
            ;;
        linux)
            "./dist/$name/$name" -V
            "./dist/$name/$name" -h
            ;;
        *)
            printf >&2 "warning: unknown OS type: %s; assuming unix-like\n" "$sys"
            "./dist/$name/$name" -V
            "./dist/$name/$name" -h
            ;;
    esac
}

clean_up ()
{
    restore_version
    exit 1
}

find_main_py ()
{
    if test "${MAIN_PY-}"; then
        if test -f "$MAIN_PY"; then
            main_py="$MAIN_PY"
        else
            printf >&2 "error: invalid MAIN_PY: %s\n" "$MAIN_PY"
            return 1
        fi
    elif test -f "main.py"; then
        main_py="main.py"
    elif test -f "$name.py"; then
        main_py="$name.py"
    else
        printf >&2 "error: unable to find main py, specify with environment variable MAIN_PY\n"
        return 1
    fi

    if test "${VERSION_PY-}"; then
        if test -f "$VERSION_PY"; then
            version_py="$VERSION_PY"
        else
            printf >&2 "error: invalid MAIN_PY: %s\n" "$MAIN_PY"
            return 1
        fi
    elif grep -q "$version_pattern" "$main_py"; then
        version_py="$main_py"
    else
        for x in ./*.py; do
            test -f "$x" || continue
            if grep -q "$version_pattern" "$x"; then
                version_py="$x"
                break
            fi
        done
        if ! test -f "$version_py"; then
            printf >&2 "warning: unable to find version py, specify with environment variable VERSION_PY\n"
        fi
    fi
}

main ()
{
    local main_py version_py=
    local version_pattern='^\(VERSION\|__version__\) = .*'
    local name description original_version
    local os_type
    set_os_type || return
    init || return
    find_main_py || return
    update_version
    build || { restore_version; return 1; }
    restore_version
    copy_scripts
    copy_profiles
    copy_docs
    archive
    test_ver_and_help
}

main "$@"
