fish_vi_key_bindings
bind -M insert -m default jj force-repaint
# starship init fish | source

# function fish_mode_prompt
#   switc $fish_bind_mode
#     case default
#       set_color --bold red
#       echo 'N'
#     case insert
#       set_color --bold green
#       echo 'I'
#     case replace_one
#       set_color --bold green
#       echo 'R'
#     case visual
#       set_color --bold brmagenta
#       echo 'V'
#     case '*'
#       set_color --bold red
#       echo '?'
#   end
#   set_color normal
# end
