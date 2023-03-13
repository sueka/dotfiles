#
# Skip all when not interactive
#
if ! [[ "$-" = *i* ]]; then
	return 0
fi

#
# Set common variables
#
LF='
'

brew_install_path=$(brew --prefix)

#
# Set export common envvars
#
export PS1='\u@\h \w\$ '

#
# Enable completions
#
source /opt/local/sign/bin/bash_complete_sign.sh

if [[ -r "$brew_install_path"/etc/profile.d/bash_completion.sh ]]; then
	source "$brew_install_path"/etc/profile.d/bash_completion.sh
fi

if [[ -d "$brew_install_path"/etc/bash_completion.d ]]; then
	source "$brew_install_path"/etc/bash_completion.d/*
fi

source <(kubectl completion bash)
source <(npm completion)

# travis gem adds:
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh
