#
# Set common variables
#
brew_install_path=$(dirname "$(dirname "$(command -v brew)")") # TODO: use `brew --prefix <formula>`. See also https://github.com/Homebrew/brew/issues/3097

#
# Set export common envvars
#
export LANG='en_US.UTF-8'
export PATH="$brew_install_path/sbin:$PATH" # brew doctor suggests

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
alias jshell="JAVA_HOME=$(/usr/libexec/java_home -Fv 14) jshell"
# rbenv
eval "$(rbenv init -)"
# nodenv
eval "$(nodenv init -)"
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
	source "$HOME/.bashrc" # NOTE: ここで conda 用にセットアップされた $PS1 が飛ぶ。
fi

#
# Register aliases
#
_git_extended() {
	if ! command -v git >/dev/null; then
		git
	fi

	if [ "$1" = home ]; then
		if [ -n "$2" ]; then
			echo >&2 "${@:2}: invalid option"
			echo >&2 'usage: git home'

			return 64 # EX_USAGE
		fi

		if ! git phd 2>/dev/null; then # defined in ~/.gitconfig
			return 70 # EX_SOFTWARE; `git <foo>` (<foo> is undefined) exits with zero
		fi

		cd "$(git phd)"
	else
		git "$@"
	fi
}

alias git=_git_extended

_cd_extended() {
	if ! command -v mdfind 1>/dev/null && ! command -v fzf 1>/dev/null; then
		cd "$@"
		return $?
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
			options=("$argument")
		else
			operands+=("$argument")
		fi
	done

	if (( ${#operands[@]} != 1 )); then
		cd "$@"
		return $? # non-zero
	fi

	destination_name=${operands[0]}

	if [ -z "$destination_name" ]; then
		return 71 # EX_OSERR
	fi

	dirs=$(mdfind -onlyin . "(kMDItemContentTypeTree == public.folder || kMDItemContentTypeTree == dyn.*) && kMDItemFSName == $destination_name")

	if [ -z "$dirs" ]; then
		# NOTE: `cd <path>` の形式で実行された場合（ `cd /`, `cd ~`, `cd ..`, `cd ./foo`, `cd foo/bar` など）もこゝに到達する。

		if cd "$@" 2>/dev/null; then
			return 0
		fi

		echo >&2 "bash: _cd_extended: $@: No such file or directory"
		return 64 # EX_USAGE
	fi

	dir=$(echo "$dirs" | fzf -0 -1)
	fzf_exit_status=$?

	if (( $fzf_exit_status != 0 )); then
		return $fzf_exit_status
	fi

	if [ -z "$dir" ]; then
		echo >&2 "Unreachable Error" # NOTE: fzf は no match なら 1 で終了する。 cf. `man fzf`
		return 70 # EX_SOFTWARE
	fi

	cd "${options[@]}" "$dir"
}

alias cd=_cd_extended
