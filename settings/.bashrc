#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

### ALIASES
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

### reporting tools - install when not installed
# fetch
# hfetch
# neofetch
# pfetch
# screenfetch
# sfetch

### Oh My Posh
#eval "$(oh-my-posh init bash)"

### Starship
eval "$(starship init bash)"
