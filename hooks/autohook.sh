#!/usr/bin/env bash

# autohook is a git hook manager that automatically creates symlinks of all 
# scripts in the hooks directory, makes each script an executable, and then
# executes them by hook-type.

install() {
    hook_types=(
        # "applypatch-msg"
        # "commit-msg"
        # "post-applypatch"
        # "post-checkout"
        # "post-commit"
        # "post-merge"
        # "post-receive"
        # "post-rewrite"
        # "post-update"
        # "pre-applypatch"
        # "pre-auto-gc"
        "pre-commit"
        "pre-push"
        # "pre-rebase"
        # "pre-receive"
        # "prepare-commit-msg"
        # "update"
    )

    # Create symlinks of scripts in hooks directory to .git/hooks directory
    # if they already do not exist
    repo_root=$(git rev-parse --show-toplevel)
    hooks_dir="$repo_root/.git/hooks"
    autohook_linktarget="../../hooks/autohook.sh"
    for hook_type in "${hook_types[@]}"
    do
        hook_symlink="$hooks_dir/$hook_type"
        if [ ! -f "$hook_symlink" ]
        then
            ln -s "$autohook_linktarget" "$hook_symlink"
        fi
    done
}

main() {
    calling_file=$(basename $0)

    # Run only during initial installation
    if [[ $calling_file == "autohook.sh" ]]
    then
        command=$1
        if [[ $command == "install" ]]
        then
            install
        fi
    else
        # Identify hook types in hooks directory and .git/hooks directory, and
        # number of scripts present of each type
        repo_root=$(git rev-parse --show-toplevel)
        hook_type=$calling_file
        symlinks_dir="$repo_root/hooks/$hook_type"
        files=("$symlinks_dir"/*)
        number_of_symlinks="${#files[@]}"
        if [[ $number_of_symlinks == 1 ]]
        then
            if [[ "$(basename ${files[0]})" == "*" ]]
            then
                number_of_symlinks=0
            fi
        fi

        echo "Found $number_of_symlinks $hook_type hook(s)"
        echo

        # Run scripts if present
        if [[ $number_of_symlinks -gt 0 ]]
        then
            hook_exit_code=0
            for file in "${files[@]}"
            do
                scriptname=$(basename $file)
                echo "Initiating hook: $scriptname"

                # Make script an executable
                chmod +x $file

                # Run script
                eval $file
                script_exit_code=$?
                if [[ $script_exit_code != 0 ]]
                then
                    hook_exit_code=$script_exit_code
                fi
                echo "Finished hook: $scriptname"
                echo
            done
            
            # Reject commit if hook yielded an exit code other than zero
            if [[ $hook_exit_code != 0 ]]
            then
                echo "Commit rejected ($hook_type hook yielded exit code $hook_exit_code)"
                exit $hook_exit_code
            fi
        fi
    fi
}

main "$@"