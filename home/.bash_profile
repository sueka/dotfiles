#
# Set common variables
#
# TODO: Use `brew --prefix <formula>` instead. See also https://github.com/Homebrew/brew/issues/3097.
brew_install_path=$(dirname "$(dirname "$(command -v brew)")")

#
# Set export common envvars
#
export LANG='en_US.UTF-8'
export PATH="$brew_install_path/sbin:$PATH" # `brew doctor` suggests

#
# Setup utilities
#
# openssl
export PATH="$brew_install_path/opt/openssl/bin:$PATH"
# SQLite
export PATH="$brew_install_path/opt/sqlite/bin:$PATH"
# Rust
export PATH="$HOME/.cargo/bin:$PATH"
# LLVM
export PATH="$brew_install_path/opt/llvm/bin:$PATH"
# Go
export GOPATH="$HOME/go"
export GO111MODULE=on
export PATH="$GOPATH/bin:$PATH"
# MySQL
export PATH="$brew_install_path/opt/mysql@5.7/bin:$PATH"
export DYLD_LIBRARY_PATH="$brew_install_path/opt/mysql@5.7:$DYLD_LIBRARY_PATH"
# Java
export JAVA_HOME=$(/usr/libexec/java_home -Fv 1.8)
export PATH="$JAVA_HOME/bin:$PATH"
alias jshell="JAVA_HOME=$(/usr/libexec/java_home -F) jshell"
# rbenv
eval "$(rbenv init -)"
# nodenv
eval "$(nodenv init -)"
# Deno
export PATH="$HOME/.deno/bin:$PATH"
# fuck
eval "$(thefuck --alias)"
# miniconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/local/Caskroom/miniconda/base/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
	eval "$__conda_setup"
else
	if [ -f "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
		. "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
	else
		export PATH="/usr/local/Caskroom/miniconda/base/bin:$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<

#
# Configure utilities
#
# less
export LESS='-JNR -j.5'
export LESSOPEN="| $brew_install_path/bin/src-hilite-lesspipe.sh %s"

#
# Load .bashrc
#
if [[ -r "$HOME/.bashrc" ]]; then
	source "$HOME/.bashrc" # Reverts PS1 set by miniconda.
fi

#
# Register aliases
#
#
# git phd - Prints Home Directory.
# git home - Goes home.
#
_git_extended() {
	if ! command -v git >/dev/null; then
		git "$@"
		return
	fi

	if [ "$1" = phd ]; then
		if [ -n "$2" ]; then
			echo >&2 "${@:2}: invalid option"
			echo >&2 'usage: git phd'

			return 64 # EX_USAGE
		fi

		(cd "$(git rev-parse --git-dir)/.."; pwd)
		return
	fi

	if [ "$1" = home ]; then
		if [ -n "$2" ]; then
			echo >&2 "${@:2}: invalid option"
			echo >&2 'usage: git home'

			return 64 # EX_USAGE
		fi

		cd "$(git rev-parse --git-dir)/.." # cd "$(git phd)"
		return
	fi

	git "$@"
}

alias git=_git_extended

#
# cd
#
_cd_extended() {
	if ! command -v mdfind 1>/dev/null && ! command -v fzf 1>/dev/null; then
		cd "$@"
		return
	fi

	optionEnds=false
	options=()
	operands=()

	for argument
	do
		if [ "$argument" = '--' ]; then
			optionEnds=true
			continue
		fi

		if ! $optionEnds && [[ "$argument" == -* ]]; then
			options+=("$argument")
		else
			operands+=("$argument")
		fi
	done

	if (( ${#operands[@]} != 1 )); then
		cd "$@" # cd: too many arguments
		return
	fi

	destination_name=${operands[0]}

	if [ -z "$destination_name" ]; then
		return 71 # EX_OSERR
	fi

	dirs=$(mdfind -onlyin . "(kMDItemContentTypeTree == public.folder || kMDItemContentTypeTree == dyn.*) && kMDItemFSName == $destination_name")

	if [ -z "$dirs" ]; then
		# NOTE: `cd <path>` の形式で実行された場合はこゝに到達する:
		#
		# - `cd /`
		# - `cd ~`
		# - `cd ..`
		# - `cd foo`
		# - `cd ./foo`
		# - `cd foo/bar`

		if cd "$@" 2>/dev/null; then
			return 0
		fi

		echo >&2 "bash: _cd_extended: $@: No such file or directory"
		return 64 # EX_USAGE
	fi

	dir=$(echo "$dirs" | fzf -0 -1)
	fzf_exit_status=$?

	# NOTE: The fzf command exits with 1 if there are no match. See also `man fzf`.
	if (( $fzf_exit_status != 0 )); then
		return $fzf_exit_status
	fi

	if [ -z "$dir" ]; then
		echo >&2 "Unreachable Error"
		return 70 # EX_SOFTWARE
	fi

	cd "${options[@]}" "$dir"
}

alias cd=_cd_extended
