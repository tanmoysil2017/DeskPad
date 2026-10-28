export DEVELOPER_DIR := env_var_or_default("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")

build_dir := justfile_directory() / ".build"
applications_dir := "/Applications"

# Build the complete Release app, ad-hoc signed for local use.
build:
    xcodebuild -project DeskPad.xcodeproj -scheme DeskPad -configuration Release \
        -destination 'generic/platform=macOS' -derivedDataPath "{{build_dir}}" \
        CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= build

# Build and install the complete app bundle, removing obsolete bundle files.
deploy: build
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{applications_dir}}" == "/Applications" ]] && pgrep -x DeskPad >/dev/null; then
        echo "Quit DeskPad before running just deploy." >&2
        exit 1
    fi
    mkdir -p "{{applications_dir}}"
    /usr/bin/rsync -a --delete "{{build_dir}}/Build/Products/Release/DeskPad.app/" "{{applications_dir}}/DeskPad.app/"
    echo "Installed {{applications_dir}}/DeskPad.app"
