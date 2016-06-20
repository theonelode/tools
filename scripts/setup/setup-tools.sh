#!/bin/sh

# Get the name of tools directory.
# Script is currently stored in 'scripts/setup/'
toolsDir=$(dirname $0)/../..

setup(){    

    cd "$toolsDir"

    if pwd | grep -Pq "$HOME($|/)"; then
        # Setting up the tools locally for a user.
        local marker="$(whoami)-tools-marker"
    else
        # Setting up tools in a common directory (implied to be system-wide)
        local marker="core-tools-marker"
        local global=1
    fi
    

    # Using the WINDIR environment variable as a lazy litmus test for
    #   whether or not we're in a Windows machine using MobaXterm.
    if [ -n "$WINDIR" ]; then
        # Windows
        # In MobaXterm-style tmux, .bashrc is not loaded for shell sessions within tmux.
        # Not using .bash_profile globally for the moment because a Debian-based system
        #     will not load .bashrc at all if .bash_profile is present. Will deal with that later.
        # Note: MobaXterm ignores the concept of a global setup. No use case for it.
        local file="$HOME/.bash_profile"
    else
        # Unix

        case "$SHELL" in
        "/bin/bash")
            if uname | grep -qi "^Darwin" || uname | grep -qi "FreeBSD"; then
                printf "BSD-like operations are not supported at this time.\n"
                exit 3
            fi

            if [ -z "$global" ]; then
                # Local
                local file="$HOME/.bashrc"
            else
                # Global
                # The global file varies from distribution or distribution.
                # /etc/bashrc - Fedora/CentOS
                # /etc/bash.bashrc - Ubuntu
                for __file in /etc/bashrc /etc/bash.bashrc; do
                    if [ -f "$__file" ]; then
                        local file="$__file"
                    fi
                done

                if [ -z "$file" ]; then
                    printf "Unable to find a global BASH profile file to attach the tools loader to.\n"
                    exit 2
                fi
            fi
            ;;
        *)
            printf "Unsupported shell: %s\n" "$SHELL" >&2
            exit 1
            ;;
         esac
    fi

    if [ ! -f "$file" ] || ! grep -q "$marker" "$file"; then

        # If we are writing to a path outside of our home directory,
        #     then it is assumed that we have write permissions (probably from being root).
        printf "Applying source statement to $file\n"
        cat << EOF >> "$file"

#####################################
# $marker
if printf "\$-" | grep -q i; then
    toolsDir="$(pwd)"
    if [ -f "\$toolsDir/bash/bashrc" ]; then
        . \$toolsDir/bash/bashrc
    fi
fi
#####################################

EOF
    fi

}

setup