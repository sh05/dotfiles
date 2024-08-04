#!/bin/bash

# tmuxの1つ目のPaneであればvpn自動接続の判定を実行
if [[ ${TMUX_PANE} = "%0" ]]; then
    vpn_connect
fi
