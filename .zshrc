# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias ll='ls -al'
alias c='clear'
alias aws-check='ensure_aws_sso_login'
alias aws-status='AWS_PROFILE=dev-engineer aws sts get-caller-identity'
alias aws-whoami='echo "Current AWS Identity:" && aws sts get-caller-identity'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# exports
export PATH="$HOME/.local/bin:$PATH"

# zsh vi mode (maybe get this through zinit?)
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# jenv & python setup
eval "$(jenv init -)"
jenv enable-plugin export
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Function to check and ensure AWS SSO login
ensure_aws_sso_login() {
    local profile=${1:-default}
    if AWS_PROFILE="$profile" aws ssm get-parameters --names "nonexistent" >/dev/null 2>&1; then
        echo "✅ Already logged in to AWS profile: $profile"
        return 0
    else
        echo "🔐 AWS SSO login required for profile: $profile"
        AWS_PROFILE="$profile" aws sso login
        return $?
    fi
}

awslogin() {
  aws sso login --profile "$1"
}

# Ensure AWS SSO login for required profiles
ensure_aws_sso_login "dev-engineer"
ensure_aws_sso_login "internal-engineer"

# Set up PIP index URL (requires internal-engineer profile to be logged in)
export PIP_INDEX_URL=$(AWS_PROFILE=internal-engineer aws ssm get-parameter --name /pypi/PYPI_SHARED_READONLY_URL --with-decryption --output text --query Parameter.Value 2>/dev/null || echo "https://pypi.org/simple/")

# AWS Helpers
# SQS helpers
export AWS_PROFILE=test-engineer
localsqs() {
    AWS_ACCESS_KEY_ID="test" \
    AWS_SECRET_ACCESS_KEY="test" \
    AWS_DEFAULT_REGION="us-east-1" \
    aws sqs --endpoint-url=http://localhost:4566 "$@"
}

testsqs_pr() {
    AWS_PROFILE=test-engineer \
    aws sqs "$@"
}
# Parameter store helper
get_ssm_value() {
    aws --profile test-engineer ssm get-parameter \
        --name "$1" \
        --query 'Parameter.Value' \
        --output text
}

# location of Cursor agent
export PATH="$HOME/.local/bin:$PATH"

# ssh text fix
export TERM=xterm-256color

# .dotfiles repo
alias config="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}
