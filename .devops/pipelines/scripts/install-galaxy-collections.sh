#!/usr/bin/env bash
# Install Ansible Galaxy collections with a skip-if-present check and retries.
# Fresh agents often time out on galaxy.ansible.com; other agents already have
# the collection cached from a previous job.
set -u

install_collection() {
    local name="$1"
    if ansible-galaxy collection list 2>/dev/null | grep -qE "^${name}[[:space:]]"; then
        echo "${name} already installed"
        return 0
    fi

    local attempt
    for attempt in 1 2 3; do
        echo "Installing ${name} (attempt ${attempt}/3)"
        if ansible-galaxy collection install "${name}" --timeout 180; then
            return 0
        fi
        echo "Galaxy install of ${name} failed on attempt ${attempt}"
        if [ "${attempt}" -lt 3 ]; then
            sleep 15
        fi
    done

    echo "Failed to install ${name} from Galaxy after 3 attempts"
    return 1
}

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <namespace.collection> [namespace.collection...]"
    exit 1
fi

for collection in "$@"; do
    install_collection "${collection}" || exit 1
done
