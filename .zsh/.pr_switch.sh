# prompt
echo "
Switch Prompt Style
"
((PR_LINE=!PR_LINE))

if (($PR_LINE)); then
zstyle ':vcs_info:git:*' formats "%K{226}%F{000} [%b]%c%u %k%f"
PROMPT=$REMOTE_ALERT"%F{000}%K{046} %n@%m %k%f%F{046}%K{214}%f%F{000} %d %f%k%F{214}%K{045}%f%F{000} %D %T %f%k%F{045}%K{226}%f%k"
PROMPT=$PROMPT\$vcs_info_msg_0_
PROMPT=$PROMPT"%F{226}%f
%K{196} %k%F{196}%f"
RPROMPT=""
else
zstyle ':vcs_info:git:*' formats "%F{226}[%b]%c%u%f"
PROMPT=$REMOTE_ALERT"%F{046}[%n@%m]%f%F{046}%F{214}[%d]%f%F{045}[%D %T]%f"
RPROMPT=\$vcs_info_msg_0_
PROMPT=$PROMPT"
%F{196}->%f"
fi
