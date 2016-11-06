#!/bin/bash -eu

# Resolve dependencies and download plugins given on the command line
#
# FROM jenkins
# RUN install-plugins.sh docker-slaves github-branch-source
# Only slightly modified for BSW Docker image to use different ENV variables and read plugin list from a file

set -o pipefail

REF_DIR=${JENKINS_REF_DIR}
FAILED="$REF_DIR/failed-plugins.txt"

. /src/plugins/jenkins-support

getLockFile() {
    printf '%s' "$REF_DIR/${1}.lock"
}

getArchiveFilename() {
    printf '%s' "$REF_DIR/${1}.jpi"
}

download() {
    local plugin originalPlugin version lock ignoreLockFile
    plugin="$1"
    version="${2:-latest}"
    ignoreLockFile="${3:-}"
    lock="$(getLockFile "$plugin")"

    if [[ $ignoreLockFile ]] || mkdir "$lock" &>/dev/null; then
        if ! doDownload "$plugin" "$version"; then
            # some plugin don't follow the rules about artifact ID
            # typically: docker-plugin
            originalPlugin="$plugin"
            plugin="${plugin}-plugin"
            if ! doDownload "$plugin" "$version"; then
                echo "Failed to download plugin: $originalPlugin or $plugin" >&2
                echo "Not downloaded: ${originalPlugin}" >> "$FAILED"
                return 1
            fi
        fi

        if ! checkIntegrity "$plugin"; then
            echo "Downloaded file is not a valid ZIP: $(getArchiveFilename "$plugin")" >&2
            echo "Download integrity: ${plugin}" >> "$FAILED"
            return 1
        fi

        resolveDependencies "$plugin"
    fi
}

doDownload() {
    local plugin version url jpi
    plugin="$1"
    version="$2"
    jpi="$(getArchiveFilename "$plugin")"

    # If plugin already exists and is the same version do not download
    if test -f "$jpi" && unzip -p "$jpi" META-INF/MANIFEST.MF | tr -d '\r' | grep "^Plugin-Version: ${version}$" > /dev/null; then
        echo "Using provided plugin: $plugin"
        return 0
    fi
    JENKINS_UC="https://updates.jenkins.io"
    JENKINS_UC_DOWNLOAD=${JENKINS_UC_DOWNLOAD:-"$JENKINS_UC/download"}

    url="$JENKINS_UC_DOWNLOAD/plugins/$plugin/$version/${plugin}.hpi"

    echo "Downloading plugin: $plugin from $url"
    curl --connect-timeout ${CURL_CONNECTION_TIMEOUT:-20} --retry ${CURL_RETRY:-5} --retry-delay ${CURL_RETRY_DELAY:-0} --retry-max-time ${CURL_RETRY_MAX_TIME:-60} -s -f -L "$url" -o "$jpi"
    return $?
}

checkIntegrity() {
    local plugin jpi
    plugin="$1"
    jpi="$(getArchiveFilename "$plugin")"

    unzip -t -qq "$jpi" >/dev/null
    return $?
}

resolveDependencies() {
    local plugin jpi dependencies
    plugin="$1"
    jpi="$(getArchiveFilename "$plugin")"

    dependencies="$(unzip -p "$jpi" META-INF/MANIFEST.MF | tr -d '\r' | tr '\n' '|' | sed -e 's#| ##g' | tr '|' '\n' | grep "^Plugin-Dependencies: " | sed -e 's#^Plugin-Dependencies: ##')"

    if [[ ! $dependencies ]]; then
        echo " > $plugin has no dependencies"
        return
    fi

    echo " > $plugin depends on $dependencies"

    IFS=',' read -r -a array <<< "$dependencies"

    for d in "${array[@]}"
    do
        plugin="$(cut -d':' -f1 - <<< "$d")"
        if [[ $d == *"resolution:=optional"* ]]; then
            echo "Skipping optional dependency $plugin"
        else
            local pluginInstalled
            if pluginInstalled="$(echo "${bundledPlugins}" | grep "^${plugin}:")"; then
                pluginInstalled="${pluginInstalled//[$'\r']}"
                local versionInstalled; versionInstalled=$(versionFromPlugin "${pluginInstalled}")
                local minVersion; minVersion=$(versionFromPlugin "${d}")
                if versionLT "${versionInstalled}" "${minVersion}"; then
                    echo "Upgrading bundled dependency $d ($minVersion > $versionInstalled)"
                    download "$plugin" &
                else
                    echo "Skipping already bundled dependency $d ($minVersion <= $versionInstalled)"
                fi
            else
                download "$plugin" &
            fi
        fi
    done
    wait
}

versionFromPlugin() {
    local plugin=$1
    if [[ $plugin =~ .*:.* ]]; then
        echo "${plugin##*:}"
    else
        echo "latest"
    fi

}

installedPlugins() {
    for f in "$REF_DIR"/*.jpi; do
        PLUGIN_NAME="$(basename "$f" | sed -e 's/\.jpi//'):$(get_plugin_version "$f")"
        echo $PLUGIN_NAME
        echo $PLUGIN_NAME >> ${JENKINS_BIN_DIR}/installed_plugins.txt
    done
}

main() {
    local plugin version
    readarray PLUGIN_LIST < /src/plugins/install_plugins.txt

    mkdir -p "$REF_DIR" || exit 1

    # Create lockfile manually before first run to make sure any explicit version set is used.
    echo "Creating initial locks..."
    for plugin in "${PLUGIN_LIST[@]}"; do
        mkdir "$(getLockFile "${plugin%%:*}")"
    done

    # have not seen any bundled plugins with Jenkins war, so removed
    bundledPlugins=""

    echo "Downloading plugins..."
    for plugin in "${PLUGIN_LIST[@]}"; do
        version=""

        if [[ $plugin =~ .*:.* ]]; then
            version=$(versionFromPlugin "${plugin}")
            plugin="${plugin%%:*}"
        fi

        download "$plugin" "$version" "true" &
    done
    wait

    echo "Installed plugins:"
    installedPlugins

    if [[ -f $FAILED ]]; then
        echo "Some plugins failed to download!" "$(<"$FAILED")" >&2
        exit 1
    fi

    echo "Cleaning up locks"
    rm -r "$REF_DIR"/*.lock
}

main "$@"
