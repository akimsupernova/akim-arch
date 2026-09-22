hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

hl.bind("SUPER + mouse_up",   hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))

hl.bind("SUPER + ALT + K", hl.dsp.exec_cmd("qs -c tools ipc call tools calculator"), { description = "Quickshell: Calculator" })
--hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("qs -c tools ipc call tools monitor"), { description = "Quickshell: Monitor settings" })
