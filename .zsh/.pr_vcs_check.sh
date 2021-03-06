# prompt
echo "
Switch Prompt Git Check 
"

((HEAVY_PR=!HEAVY_PR))

if (($HEAVY_PR)); then
zstyle ':vcs_info:git:*' check-for-changes true
else
zstyle ':vcs_info:git:*' check-for-changes false
fi
