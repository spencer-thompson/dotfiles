#!/usr/bin/env bash
set -u  #Detect undefined variable
set -o pipefail #Return return code in pipeline fails

# Target: Control player (spotify/vlc/cmus/audacious/rhythmbox/clementine) via MPRIS D-Bus interface (MediaPlayer2.Player) On GNU/Linux.

# Developer: MaxdSre

# Change Log:
# - Jun 12, 2020 10:15 Thu ET - first draft
# - Jun 16, 2020 10:46 Tue ET - finish essential functions (play control, postion seek, sink volume mute/unmute toggle, spotify advertisement mute)
# - Jun 17, 2020 21:10 Wed ET - add notification silent option, support Polybar ipc module
# - Jun 18, 2020 10:08 Thu ET - fix issue metadata extraction omit when string contains quotation marks (") or vertical bar (|), add support PlayPause for Chromium/Firefox Web browser
# - Jun 19, 2020 11:36 Fri ET - notification icon auto change based on choosed player (support Chromium/Google Chrome/Mozilla Firefox); player Application name extraction and usage optimization
# - Jun 19, 2020 21:05 Fri ET -  add player session resetting option when multiple players existed
# - Jun 20, 2020 09:50 Sat ET - add player application name output and track info notification for Polybar, testing some player icon (Audacious/Clementine/Rhythmbox)
# - Jun 21, 2020 20:39 Sun ET - enchance integration with Polybar, auto start mpris bar when mpris player detected
# - Jun 22, 2020 10:16 Mon ET - auto select first ordered players if dmenu replacement 'rofi' not exist; exchange '-m', '-t' meaning;
# - Jun 22, 2020 16:13 Mon ET - add sink volume up/down seek function
# - Jun 23, 2020 08:21 Tue ET - make Spotify official client 'stop' action work; fix notification not show default icon if variable 'player_specify' is empty.
# - Jun 24, 2020 16:18 Wed ET - add notification for Spotify advertisement track mute action
# - ~ Jun 26, 2020 10:18 Fri ET - merge Mpris player D-Bus & sink metedata info, include notification icon
# - Jun 27, 2020 19:10 Sat ET - add current player process kill action
# - Jul 02, 2020 20:00 Thu ET - redesign & optimize Mpris player D-Bus & sink metedata info releation table
# - Jul 03, 2020 14:49 Fri ET - dbus-send add reply timeout, optimize D-Bus & Sink releation table invoke procedure
# - Jul 08, 2020 17:49 Fri ET - Create session save path for current login user to support multi users
# - Aug 01, 2020 18:00 Sat ET - Mozilla Firefox change command name from 'firefox-bin' to 'MainThread'
# - Aug 12, 2020 09:07 Wed ET - add support for Opera web browser
# - Aug 13, 2020 09:36 Thu ET - add support for Vivaldi web browser
# - Nov 14, 2020 10:02 Sat ET - add support for tidal-hifi but Papirus icon theme has no specific icon


# Document:
# - https://specifications.freedesktop.org/mpris-spec/latest/
# - https://dbus.freedesktop.org/doc/dbus-specification.html
# - https://wiki.archlinux.org/index.php/Spotify
# - https://wiki.archlinux.org/index.php/Music_Player_Daemon


# - Dependencies
# Icon theme|Papirus|https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
# Iconic font|Nerd Fonts|https://github.com/ryanoasis/nerd-fonts
# Status bar|Polybar|https://github.com/polybar/polybar
# dmenu replacement|Rofi|https://github.com/davatorium/rofi
# Notification daemon|Dunst|https://github.com/dunst-project/dunst
# Sound server|PulseAudio|https://wiki.archlinux.org/index.php/PulseAudio

# - Corresponding Polybar mpris modules
# https://gitlab.com/axdsop/nixnotes/blob/master/GNULinux/Dotfiles/_Config/i3/polybar/modules/mpris_module

# - Spotify advertisement track mute for free account
# First: if possibile, please join Spotify Premium plans.
# As I can't get current track position directly from Spotify official client via MPRIS D-bus interface, I can't set how long the sink volume should be muted (also track position seek). So currently if the player is playing advertisements (may be 2 tracks), just click 'next' icon (嶺 uf9ab) on Polybar mpris bar. It will keeps muted status until the normal track begin to play.

# - Development Plan Note
# For Spotify advertisement mute, still need to be tested.
# Support Advanced Linux Sound Architecture (ALSA) amixer ?
# keep track sink volume setting when stop/next/previous for web browser ?


#########  0-1. Variables Setting  #########
p_action=${p_action:-}  # Play/Pause/PlayPause/Stop/Next/Previous
p_status_check=${p_status_check:-0}  # Playing|Paused|Stopped
p_position_jump=${p_position_jump:-}  # SetPosition
p_position_seek=${p_position_seek:-}  # Seek
p_track_metadata_list=${p_track_metadata_list:-0}
d_list_all=${d_list_all:-0}    # List the names of running players that can be controlled
p_sink_volume_toggle=${p_sink_volume_toggle:-0}
p_sink_volume_seek=${p_sink_volume_seek:-}
p_quiet_notification=${p_quiet_notification:-0}
p_session_reset=${p_session_reset:-0}
p_session_save_path=${p_session_save_path:-'/tmp/.mpris_player_session'} # save player instance name and timestamp    ${p_session_save_path}_$USER

# For true players: spotify/vlc/cmus/audacious/rhythmbox/clementine and others.
player_specify=${player_specify:-}
player_app_name=${player_app_name:-}
player_kill_signal=${player_kill_signal:-0}

# Polybar for mpris
polybar_mpris_bar_name=${polybar_mpris_bar_name:-}
player_instance_sink_info=${player_instance_sink_info:-}

# Notification Icon theme dir /usr/share/icons/   https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
notification_icon_default=${notification_icon_default:-'multimedia-player'}

readonly mpris_mediaplayer='org.mpris.MediaPlayer2'
# mpris_bus_name="${mpris_mediaplayer}.${player_specify}"
mpris_entry_point='/org/mpris/MediaPlayer2'
mpris_interface="${mpris_mediaplayer}.Player"

# dbus-send
# --system   Send to the system message bus.
# --session  Send to the session message bus. (This is the default.)
readonly dbus_reply_timeout=150  # milliseconds, e.g. 500 is 0.5 second
dbus_send_comm="dbus-send --session --print-reply --reply-timeout=${dbus_reply_timeout}"


#########  0-2 getopts Operation  #########
fn_HelpInfo(){
echo -e "\e[33mUsage:
    script [options] ...
    script | bash -s -- [options] ...

Operating player via MPRIS D-Bus interface (MediaPlayer2.Player) On GNU/Linux.

Project url: https://github.com/MaxdSre/mpris-player-control

For true players: VLC/cmus/Spotify/Audacious/Clementine/Rhythmbox and others.
Also support Web Browser Mozilla Firefox/Google Chrome/Chromium/Brave/Opera/Vivaldi.

Attention: not all functions supported by every player.

Support Polybar ipc module (https://github.com/polybar/polybar/wiki/Module:-ipc)

[available option]
    -h    --help, show help info
    -l    --list the names of running players that can be controlled
    -c    --check player playing status (Playing|Paused|Stopped)
    -t    --output current track metadata
    -k    --kill current player instance process via 'killall'
    -b polybar_name    --specify Polybar bar name used for MPRIS (if no running mpris player detected, specified bar will be quitted automatically).
    -p player_name    --specify player name (spotify/vlc/cmus/audacious/rhythmbox/clementine...), default is auto detect
    -a action_type    --specify player play action (Play/Pause/PlayPause/Stop/Next/Previous), default is show playing status
    -s seek_time    --specify player to go to the seek forward/backward OFFSET in seconds (e.g. 5 is forward offset 5s, -5 is backward offset 5s)
    -S set_time    --specify player to go to the position in seconds (less than mpris:length) (Uppercase S. e.g. 15 is go to the position 15s)
    -V sink_volume_seek    --specify player sink volume up/down OFFSETin % (Uppercase V. e.g. 5 is volume set to %5, +5 is volume up 5%, -5 is volume down 5%)
    -m    --toggle sink volume (mute/unmute) via pactl or org.freedesktop.DBus
    -q    --quiet notification via 'notify-send', default is enable
    -r    --reset player session (enable multiple players selection menu), default is disable. Via file '${p_session_save_path}' saved player instance name.
\e[0m"
}

while getopts "a:b:cklms:S:p:qtrV:h" option "$@"; do
    case "$option" in
        a ) p_action="$OPTARG" ;;
        b ) polybar_mpris_bar_name="$OPTARG" ;;
        c ) p_status_check=1 ;;
        k ) player_kill_signal=1 ;;
        s ) p_position_seek="$OPTARG" ;;
        S ) p_position_jump="$OPTARG" ;;
        l ) d_list_all=1 ;;
        t ) p_track_metadata_list=1 ;;
        p ) player_specify="$OPTARG" ;;
        q ) p_quiet_notification=1 ;;
        m ) p_sink_volume_toggle=1 ;;
        V ) p_sink_volume_seek="$OPTARG" ;;
        r ) p_session_reset=1 ;;
        h|\? ) fn_HelpInfo && exit ;;
    esac
done


#########  1-0 Preparation Function #########
fn_CommandExistIfCheck(){
    # $? -- 0 is find, 1 is not find
    local l_name="${1:-}"
    local l_output=${l_output:-1}
    [[ -n "${l_name}" && -n $(which "${l_name}" 2> /dev/null || command -v "${l_name}" 2> /dev/null) ]] && l_output=0
    return "${l_output}"
}

fn_Notification(){
    local l_body="${1:-}"
    local l_summary="${2:-"Player ${player_specify} Operation"}"
    local l_urgency="${3:-normal}" # low/normal/critical
    # 1 pid| 2 ppid| 3 binary name| 4 app name| 5 notification icon| 6 player instance
    local l_player_instance_sink_info=${l_player_instance_sink_info:-"${player_instance_sink_info}"}

    if [[ "${p_quiet_notification}" -eq 0 ]]; then
        local l_icon=${l_icon:-"${notification_icon_default}"}
        [[ -n "${l_player_instance_sink_info}" ]] && l_icon=$(cut -d\| -f 5 <<< "${l_player_instance_sink_info}")

        [[ -n "${player_specify}" ]] || l_summary="${l_summary//  / }"
        notify-send -u "${l_urgency}" -i "${l_icon}" "${l_summary}" "${l_body}"
    fi
}

fn_ExitStatement(){
    local l_str="$*"
    if [[ -n "${l_str}" ]]; then
        echo -e "${l_str}\n"
        fn_Notification "${l_str}"
    fi
    exit
}

#########  1-1 Initialization Check #########
fn_InitializationCheck(){
    # - need superuser permission
    [[ "$UID" -eq 0 ]] && fn_ExitStatement 'Please run as normal user.'

    # - get current operation normal user info
    [[ -n "${USER:-}" && -z "${SUDO_USER:-}" ]] && login_user="$USER" || login_user="$SUDO_USER"
    [[ -z "${login_user}" ]] && login_user=$(logname 2> /dev/null)
    [[ -z "${login_user}" ]] && login_user=$(ps -eo 'uname,comm,cmd' | sed -r -n '/xinit[[:space:]]+\/(root|home)\//{s@^([^[:space:]]+).*@\1@g;p}')

    # - Support multi user
    p_session_save_path="${p_session_save_path}_${login_user// /}"

    # - Player session reset
    if [[ "${p_session_reset}" -ne 0 && -f "${p_session_save_path}" ]]; then
        [[ -f "${p_session_save_path}" ]] && rm -f "${p_session_save_path}"
        fn_Notification '' 'Resetting Player Session'
        exit
    fi

    # - Dependency check
    # gawk, sed
    fn_CommandExistIfCheck 'gawk' || fn_ExitStatement "Sorry, no command 'gawk' find."
    fn_CommandExistIfCheck 'sed' || fn_ExitStatement "Sorry, no command 'sed' find."
    fn_CommandExistIfCheck 'pactl' || fn_ExitStatement "Sorry, no command 'pactl' find."
}


#########  2-1 Freedesktop D-Bus & Pactl Sink Info #########
# Sink info via pactl
fn_Player_Sink_Info_Metadata(){
    # https://wiki.archlinux.org/index.php/Spotify#pactl_(pulseaudio)

    local l_output=${l_output:-}
    l_output=$(pactl list sink-inputs 2> /dev/null | sed -r -n '/^Sink Input/{s@^[^#]+#@@g;p};/^[[:space:]]*(application.name|application.process.binary|application.process.id)/{s@^[^=]+=[[:space:]]*@@g;s@"@@g;p};/^[[:space:]]*(Mute|Corked):/{s@^[^:]+:[[:space:]]*@@g;p};/^[[:space:]]*Volume:/{s@.*?[[:space:]]+([[:digit:]]+)%.*@\1@g;p};/^$/{s@.*@---@g;p}' | sed ':a;N;$!ba;s@\n@|@g' | sed -r -n 's@\|?---\|?@\n@g;p')
    echo "${l_output}"

    # sink num|corked (playpause)|is muted|volume|app name|process id|binary name
    # 1 sink num| 2 corked (playpause)|3 is muted|4 volume| 5 app name|6 processid|7 binary name|

    # 8|no|no|100|Spotify|19018|spotify             # player spotify
    # 9|no|no|100|C* Music Player|19018|cmus        # player cmus
    # 2|no|no|100|Audacious|19018|audacious         # player audacious
    # 6|no|no|100|Rhythmbox|19018|rhythmbox         # player rhythmbox
    # 11|no|no|100|Clementine|19018|clementine      # player clementine
    # 81|no|no|100|Chromium|200250|chrome           # player chromium.instance199927
    # 14|no|no|100|Chromium||200250|brave           # player chromium.instance17224
    # 85|no|no|100|Google Chrome|200250|chrome      # Player chrome.instance42894
    # 87|no|no|100|Firefox|200250|firefox-bin       # player firefox.instance52117
    # 7|no|no|100|Opera|62078|opera                 # player Opera
}

fn_Player_Info_Metadata_Extraction(){
    local l_item_choose=${1:-} # 1 sink num| 2 corked (playpause)|3 is muted|4 volume |0 all fields
    local l_item_no=${l_item_no:-0}

    case "${l_item_choose,,}" in
        s|sink*) l_item_no=1 ;;
        c|cork*) l_item_no=2 ;;
        m|mute*) l_item_no=3 ;;
        v|vol*) l_item_no=4 ;;
        *) l_item_no=0 ;;
    esac

    local l_player_choosed_info=${2:-}
    [[ -z "${l_player_choosed_info}" ]] && l_player_choosed_info="${player_instance_sink_info}"
    # player_instance_sink_info  1 pid| 2 ppid| 3 binary name| 4 app name| 5 notification icon| 6 player instance
    local l_player_pid=$(cut -d\| -f1 <<< "${l_player_choosed_info}")
    local l_player_ppid=$(cut -d\| -f2 <<< "${l_player_choosed_info}")
    local l_player_binary_name=$(cut -d\| -f3 <<< "${l_player_choosed_info}")

    local l_sink_input_list=${l_sink_input_list:-}
    # Sink input info   1 sink num| 2 corked (playpause)|3 is muted|4 volume| 5 app name|6 processid|7 binary name|
    l_sink_input_list=$(fn_Player_Sink_Info_Metadata)
    l_player_choosed_info=$(awk -F\| 'BEGIN{OFS="|"}{if($NF=="'${l_player_binary_name}'" && ($6=="'${l_player_pid}'" || $6=="'${l_player_ppid}'")) print $1,$2,$3,$4}' <<< "${l_sink_input_list}")

    local l_output=''

    if [[ -n "${l_player_choosed_info}" ]]; then
        if [[ "${l_item_no}" -ne 0 ]]; then
            l_output=$(cut -d\| -f"${l_item_no}" <<< "${l_player_choosed_info}")
        else
            l_output="${l_player_choosed_info}"
        fi
    fi

    echo "${l_output}"
}


# global variable: mpris_dbus_list
fn_Mpris_DBus_Name_List(){
    # https://blog.csdn.net/machiner1/article/details/44936519
    # dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListActivatableNames

    # dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListActivatableNames
    # string "org.mpris.MediaPlayer2.playerctld"

    # dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames
    # string "org.mpris.MediaPlayer2.{spotify,cmus,vlc,audacious,rhythmbox,.clementine}"
    # string "org.mpris.MediaPlayer2.chromium.instance27085" # Chromium/SRWareIron/Brave
    # string "org.mpris.MediaPlayer2.chrome.instance42894"  # Google Chrome
    # string "org.mpris.MediaPlayer2.firefox.instance52117"

    # dbus-send --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.GetConnectionUnixProcessID string:'org.mpris.MediaPlayer2.spotify'

    mpris_dbus_list=${mpris_dbus_list:-}
    mpris_dbus_list=$(${dbus_send_comm} --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2> /dev/null | sed -r -n '/org.mpris.MediaPlayer2/{s@.*org.mpris.MediaPlayer2.([^"]+).*@\1@g;p}')
    # spotify / firefox.instance307821 / chromium.instance241534 / chromium.instance296096

    if [[ "${d_list_all}" -eq 1 ]]; then
        # list available mpris players
        echo "${mpris_dbus_list}"

        local l_exit_status=0

        if [[ -n "${mpris_dbus_list}" ]]; then
            # Polybar mpris bar start if not running when main bar is running
            if [[ -n "${polybar_mpris_bar_name}" ]]; then
                local l_polybar_process_info=''
                 # %p pid PID / %P ppid PPID / %U user USER / %a args COMMAND / %c comm COMMAND
                # ps --no-headers -e -o '%c|%p|%a' 2> /dev/null
                l_polybar_process_info=$(ps --no-headers -eo 'comm,pid,cmd' | sed -r -n '/^polybar[[:space:]]*/I{p}')

                if [[ -n "${l_polybar_process_info}" ]]; then
                    local l_polybar_mpris_bar_pid=''
                    l_polybar_mpris_bar_pid=$(sed -r -n '/polybar[[:space:]]+'"${polybar_mpris_bar_name}"'/{s@^[^[:digit:]]+([^[:space:]]+).*@\1@g;p}' <<< "${l_polybar_process_info}")

                    if [[ -z "${l_polybar_mpris_bar_pid}" ]]; then
                        local l_polybar_config_path=''
                        # -c ~/.config/polybar/config
                        l_polybar_config_path=$(sed -r -n '/[[:space:]]+-c[[:space:]]+/{s@.*(-c[[:space:]]*[^[:space:]]+)@\1@g;p;q}' <<< "${l_polybar_process_info}")

                        # don't use ("") for l_polybar_config_path
                        polybar "${polybar_mpris_bar_name}" ${l_polybar_config_path} &> /dev/null &
                    fi
                fi
            fi

        else
            l_exit_status=1
    
        fi

        exit "${l_exit_status}"
    fi
}


#########  2-1 Mpris Player Choose #########
fn_DBus_Sink_Relation_Table(){
    local l_sink_input_list=${l_sink_input_list:-}
    l_sink_input_list=$(fn_Player_Sink_Info_Metadata)
    # 1 sink num| 2 corked (playpause)|3 is muted|4 volume| 5 app name|6 processid|7 binary name|
    # 20|no|no|100|Chromium|241863|chrome
    # 21|no|no|100|Spotify|278531|spotify
    # 22|no|no|85|Chromium|296561|brave
    # 24|no|no|100|Firefox|307821|firefox-bin
    # 85|no|no|100|Google Chrome|200250|chrome      # Player chrome.instance42894

    local l_process_list=${l_process_list:-}
    # %p pid PID / %P ppid PPID / %U user USER / %a args COMMAND / %c comm COMMAND
    # ps --no-headers -p ${pid} -o pid,ppid,comm,cmd 2> /dev/null
    l_process_list=$(ps --no-headers -e -o '%p|%P|%c|%a' 2> /dev/null | sed -r -n 's@^[[:space:]]*@@g;s@[[:space:]]*(\|)[[:space:]]*@\1@g;p')
    # 1247194|1|spotify|/opt/spotify/spotify --force-device-scale-factor=2
    # 1238573|1|firefox-bin|firefox --...
    # 1237018|1236726|chrome|/opt/google/chrome/chrome --type=utility ...--shared-files
    # 1244265|1243900|brave|/usr/lib/brave-bin/brave --type=utility...--shared-files
    # 62078|61806|opera|/usr/lib/opera/opera --type=utility ...--shared-files=v8_snapshot_data:100
    # 38687|35252|vivaldi-bin|/opt/vivaldi/vivaldi-bin --type=utility ...--shared-files

    local l_player_instances_sink_info=''

    while read -r player_instance; do
        # Icon theme dir /usr/share/icons/
        # https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
        notification_icon="${notification_icon_default}"
        process_app_name=''

        if [[ "${player_instance}" =~ \.instance[0-9]+$ ]]; then
            player_instance_pid="${player_instance##*instance}"
            # player_instance_pid=$(sed -r -n 's@.*instance@@Ig;p' <<< "${player_instance}") # this is ppid for Chromium, pid for Firefox
            # pid|ppid|binary name|command
            process_info=$(sed -r -n '/^'"${player_instance_pid}"'\|/{p;q}' <<< "${l_process_list}")
            process_info_comm=$(cut -d\| -f 3 <<< "${process_info}")
            process_info_cmd=$(cut -d\| -f 4 <<< "${process_info}")

            case "${player_instance%%.*}" in
                chrome)
                    # chrome.instance1236726
                    # 1236726|1|chrome|/opt/google/chrome/chrome
                    if [[ "${process_info_cmd,,}" =~ google ]]; then
                        process_app_name='Google Chrome'
                        notification_icon='chrome'
                    fi
                    ;;
                chromium)
                    case "${process_info_comm}" in
                        opera*)
                            # chromium.instance61806
                            # 61806|1|opera|/usr/lib/opera/opera
                            process_app_name='Opera Web Browser'
                            notification_icon='opera'
                            ;;
                        vivaldi*)
                            # chromium.instance35252
                            # 35252|1|vivaldi-bin|/opt/vivaldi/vivaldi-bin
                            process_app_name='Vivaldi Browser'
                            notification_icon='vivaldi'
                            ;;
                        brave*)
                            # chromium.instance1243900
                            # 1243900|1243895|brave|/usr/lib/brave-bin/brave
                            if [[ "${process_info_cmd,,}" =~ \/(brave|brave-bin) ]]; then
                                process_app_name='Brave Browser'
                                notification_icon='brave'
                            fi
                            ;;
                        chrome)
                            # chromium.instance1237985
                            # 1237985|1|chrome|/opt/SRWareIron/chrome
                            if [[ "${process_info_cmd,,}" =~ \/(srware|srwareiron|iron) ]]; then
                                process_app_name='SRWare Iron'
                                notification_icon='iron_product_logo'
                            fi
                            ;;
                        chromium)
                            # chromium.instance1244602
                            # 1244602|1|chromium|/usr/lib/chromium/chromium
                            if [[ "${process_info_cmd,,}" =~ \/chromium ]]; then
                                process_app_name='Chromium'
                                notification_icon='chromium'
                            fi
                            ;;
                        tidal-hifi)
                            # https://github.com/Mastermindzh/tidal-hifi
                            process_app_name='Tidal HiFi'
                            #notification_icon='tidal'
                            ;;
                    esac
                    ;;
                firefox)
                    # firefox.instance1238573
                    # 1238573|1|firefox-bin|firefox

                    case "${process_info_comm}" in
                        firefox-bin)
                            process_app_name='Mozilla Firefox'
                            notification_icon='firefox'
                        ;;
                        MainThread)
                            if [[ "${process_info_cmd,,}" =~ \/(firefox|firefox-bin) ]]; then
                                process_app_name='Mozilla Firefox'
                                notification_icon='firefox'
                            fi
                        ;;
                    esac
                    ;;
            esac

        else
            # - player instance name without '.instance[0-9]+'

            # pid|ppid|binary name|command
            process_info=$(sed -r -n '/\|'"${player_instance}"'\|/{p;q}' <<< "${l_process_list}")
            process_info_comm=$(cut -d\| -f 3 <<< "${process_info}")


            case "${process_info_comm}" in
                cmus)
                    # cmus     1254697|728518|cmus|cmus
                    process_app_name='C* Music Player'
                    ;;
                vlc)
                    # vlc      1253746|1|vlc|/usr/bin/vlc --started-from-file
                    process_app_name='VLC media player' # VLC media player (LibVLC 3.0.11)
                    notification_icon="${process_info_comm}"
                    ;;
                spotify)
                    # spotify  1247194|1|spotify|/opt/spotify/spotify --force-device-scale-factor=2
                    process_app_name='Spotify'
                    notification_icon="${process_info_comm}"
                    ;;
                *)
                    process_app_name="${process_info_comm^}"
                    # Spotify,VLC,Audacious,Rhythmbox,clementine
                    notification_icon="${process_info_comm}"
                    ;;
            esac

        fi

        # - Comparasion with sink input info
        if [[ -n "${l_sink_input_list}" ]]; then
            # 1 sink num| 2 corked (playpause)|3 is muted|4 volume| 5 app name|6 processid|7 binary name
            sink_info=''
            # player instance 'process_info_comm' == sink input 'binary name' (7)
            sink_info=$(sed -r -n '/\|'"${process_info_comm}"'$/I{p;q}' <<< "${l_sink_input_list}")

            if [[ -n "${sink_info}" ]]; then
                [[ -z "${process_app_name}" ]] && process_app_name=$(cut -d\| -f5 <<< "${sink_info}")

                sink_input_pid=$(cut -d\| -f6 <<< "${sink_info}")
                if [[ "${sink_input_pid}" != $(cut -d\| -f1 <<< "${process_info}") ]]; then
                    process_info=$(sed -r -n '/^'"${sink_input_pid}"'\|/{p;q}' <<< "${l_process_list}")
                fi
            fi
        fi

        # pid|ppid|binary name|app name|notification icon|player instance
        echo "${process_info%|*}|${process_app_name}|${notification_icon}|${player_instance}"

        # l_player_instances_sink_info="${l_player_instances_sink_info}\n${process_info%|*}|${process_app_name}|${notification_icon}|${player_instance}"

    done <<< "${mpris_dbus_list}" | sort -r -b -f -t"|" -k 3,3

    # l_player_instances_sink_info=$(sed -r 's@\\n@\n@g' <<< "${l_player_instances_sink_info}" | sed -r -n '/^[[:space:]]+$/d;p')
    # sort by field 3 (binary name)
    # sort -r -b -f -t"|" -k 3,3 <<< "${l_player_instances_sink_info}"
}

# global variable: player_instance_sink_info
fn_Mpris_Player_Choose(){
    local l_enable_notification=0
    local l_dbus_name_count=0
    [[ -n "${mpris_dbus_list}" ]] && l_dbus_name_count=$(wc -l <<< "${mpris_dbus_list}")

    # 1 pid| 2 ppid| 3 binary name| 4 app name| 5 notification icon| 6 player instance
    # player_instance_sink_info=''

    if [[ "${l_dbus_name_count}" -eq 0 ]]; then
        fn_Notification '' 'No running player detected.'
        # https://github.com/polybar/polybar/wiki/Inter-process-messaging
        [[ -n "${polybar_mpris_bar_name}" ]] && polybar-msg cmd quit "${polybar_mpris_bar_name}" 2> /dev/null
        exit 0
    fi

    player_instances_sink_info=${player_instances_sink_info:-}

    # - Checck & verify session file if existed
    if [[ -f "${p_session_save_path}" ]]; then
        local l_existed_session_info=''
        l_existed_session_info=$(head -n 1 "${p_session_save_path}" 2> /dev/null)
        
        local l_existed_session_player=''
        # last field (6) stands for player instance
        [[ -n "${l_existed_session_info}" ]] && l_existed_session_player=$(cut -d\| -f 6 <<< "${l_existed_session_info}")

        if [[ -n "${l_existed_session_player}" && -n $(sed -r -n '/^'"${l_existed_session_player}"'$/{p;q}' <<< "${mpris_dbus_list}") ]]; then
            # %p pid PID / %P ppid PPID / %U user USER / %a args COMMAND / %c comm COMMAND            
            if [[ $(ps --no-headers -o '%c' -p $(cut -d\| -f 1 <<< "${l_existed_session_info}") 2> /dev/null) == $(cut -d\| -f 3 <<< "${l_existed_session_info}") ]]; then
                player_instances_sink_info="${l_existed_session_info}"
            fi

        fi
    fi

    if [[ -z "${player_instances_sink_info}" ]]; then
        [[ -f "${p_session_save_path}" ]] && rm -f "${p_session_save_path}"
        player_instances_sink_info=$(fn_DBus_Sink_Relation_Table)
    fi
    

    if [[ "${l_dbus_name_count}" -eq 1 ]]; then
        if [[ -n "${player_specify}" && "${player_specify}" != "${mpris_dbus_list}" ]]; then
            fn_ExitStatement "Specified player ${player_specify} is not running."
        else
            player_specify="${mpris_dbus_list}"
            player_instance_sink_info=$(sed -r -n '/\|'"${player_specify}"'$/{p}' <<< "${player_instances_sink_info}")
        fi

    else
        if [[ -n "${player_specify}" ]]; then
            player_specify="${player_specify,,}"
            player_instance_sink_info=$(sed -r -n '/\|'"${player_specify}"'$/{p}' <<< "${player_instances_sink_info}")
            [[ -z "${player_instance_sink_info}" ]] && fn_ExitStatement "Specified player ${player_specify} is not found."
        else
            local l_p_existed_session=${l_p_existed_session:-}
            [[ -f "${p_session_save_path}" ]] && l_p_existed_session=$(head -n 1 "${p_session_save_path}" 2> /dev/null)

            local l_existed_player=${l_existed_player:-}

            if [[ -n "${l_p_existed_session}" ]]; then
                # last field (6) stands for player instance
                # sed -r -n 's@.*\|([^\|]+)$@\1@g;p' <<< "${l_p_existed_session}"
                l_existed_player=$(cut -d\| -f 6 <<< "${l_p_existed_session}")

                if [[ -z $(sed -r -n '/^'"${l_existed_player}"'$/{p}' <<< "${mpris_dbus_list}") ]]; then
                    l_p_existed_session=''
                    [[ -f "${p_session_save_path}" ]] && rm -f "${p_session_save_path}"
                fi
            fi

            # choose player from list
            if [[ -n "${l_p_existed_session}" ]]; then
                player_specify="${l_existed_player}"
                player_instance_sink_info="${l_p_existed_session}"
            else
                MENU_CHOOSE=${MENU_CHOOSE:-}

                # 1 pid| 2 ppid| 3 binary name| 4 app name| 5 notification icon| 6 player instance
                if fn_CommandExistIfCheck 'rofi'; then
                    MENU_CHOOSE="$(rofi -theme ~/.config/rofi/config.rasi -sep "|" -dmenu -i -p 'Available Player Menu:' -location 2 -xoffset -15 -yoffset +50 -width 1 -hide-scrollbar -line-padding 2 -padding 10 -lines 2 -me-accept-custom <<< $(awk -F\| '{printf("%s (%s)\n",$6,$4)}' <<< "${player_instances_sink_info}" | sed ':a;N;$!ba;s@\n@|@g'))"
                    # firefox.instance1238573 (Firefox)

                    MENU_CHOOSE="${MENU_CHOOSE%% *}"
                else
                    # As this scirpt is used to integrate with Polybar, so just choose the first player orderded if rofi not exists.
                    # MENU_CHOOSE=$(awk -F\| 'NR==1{print $10)}' <<< "${player_instances_sink_info}")

                    # last field (6) stands for player instance
                    MENU_CHOOSE=$(head -n 1 <<< "${player_instances_sink_info}" | cut -d\| -f 6)

                    # - You can also choose select menu in terminal
                    # IFS_BAK=${IFS_BAK:-"$IFS"}  # Backup IFS
                    # IFS="|" # Setting temporary IFS
                    # PS3="Choose player number(e.g. 1, 2,...):"

                    # select item in $(sort -r <<< "${mpris_dbus_list}" | sed ':a;N;$!ba;s@\n@|@g'); do
                    #     MENU_CHOOSE="${item}"
                    #     [[ -n "${MENU_CHOOSE}" ]] && break
                    # done < /dev/tty

                    # IFS=${IFS_BAK}  # Restore IFS
                    # unset IFS_BAK
                    # unset PS3
                fi

                if [[ -n "${MENU_CHOOSE}" ]]; then
                    player_specify="${MENU_CHOOSE}"
                    player_instance_sink_info=$(sed -r -n '/\|'"${player_specify}"'$/{p}' <<< "${player_instances_sink_info}")
                    l_enable_notification=1
                else
                    [[ -f "${p_session_save_path}" ]] && rm -f "${p_session_save_path}"
                    fn_Notification '' "Please choose one player"
                    exit
                fi

            fi
        fi
    fi

    mpris_bus_name="${mpris_mediaplayer}.${player_specify}"

    # save choosed player instance
    echo "${player_instance_sink_info}" > "${p_session_save_path}"
    date +'%s' >> "${p_session_save_path}"

    # 1 pid| 2 ppid| 3 binary name| 4 app name| 5 notification icon| 6 player instance
    player_app_name=$(cut -d\| -f4 <<< "${player_instance_sink_info}")
    echo "${player_app_name}" >> "${p_session_save_path}"

    [[ "${l_enable_notification}" -eq 0 ]] || fn_Notification "player instance: ${player_specify}" "Player ${player_app_name}"

    # - Player instance process kill
    if [[ "${player_kill_signal}" -ne 0 ]]; then
        local l_result=${l_result:-}
        local l_action_timeout=${l_action_timeout:-3}
        local l_player_binary_name=$(cut -d\| -f3 <<< "${player_instance_sink_info}")

        fn_Notification "Begin in ${l_action_timeout} seconds..." "Player ${player_app_name} kill"
        sleep "${l_action_timeout}"
        l_result=$(killall "${l_player_binary_name}" 2>&1) # kill player instances via corresponding binary name. Default is SIGTERM, if not works, then try SIGKILL

        # [[ -f "${p_session_save_path}" ]] && rm -f "${p_session_save_path}"

        if [[ -n "${l_result}" ]]; then
            # firefox-bin: no process found
            fn_Notification 'Failed' "Player ${player_app_name} kill" 'critical'
            exit 1
        else
            sleep 1
            while true; do
                if [[ -n $(pidof -s "${l_player_binary_name}") ]]; then
                    sleep 1
                else
                    break
                fi
            done

            fn_Notification 'Successfully' "Player ${player_app_name} kill"
            exit 0
        fi
    fi
}


#########  2-3 MediaPlayer2 Track Metadata Function #########
fn_Mpris_Track_Metadata_Extraction(){
    local l_item="${1:-}"
    local l_raw_list="${2:-}"  # format like:   mpris|length|320467000
    local l_output=''
    l_output=$(sed -r -n '/\|'"${l_item}"'\|/{s@^[^\|]+\|[^\|]+\|(.*)$@\1@g;p}' <<< "${l_raw_list}")
    echo "${l_output}"
}

fn_Mpris_Track_Metadata(){
    local l_retry_count="${1:-0}"
    local l_retry_max=5

    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'
    # ${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" org.freedesktop.DBus.Properties.Get string:"${mpris_interface}" string:'Metadata' 2> /dev/null | sed -r -n '/variant.*array/d; /(string[[:space:]]+|variant[[:space:]]+)/!d; /".*"$/{s@[^"]+"(.*?)"[^"]*$@\1@g}; /variant/{s@.*[[:space:]]+@@g}; p' | sed 's@:@|@g;N;s@\n@|@g'

    local l_output=${l_output:-}
    l_output=$(${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" org.freedesktop.DBus.Properties.Get string:"${mpris_interface}" string:'Metadata' 2> /dev/null | sed -r -n '/variant.*array/d; /(string[[:space:]]+|variant[[:space:]]+)/!d; /".*"$/{s@[^"]+"(.*?)"[^"]*$@\1@g}; /variant/{s@.*[[:space:]]+@@g}; p' | sed 's@:@|@g;N;s@\n@|@g')

    if [[ $(cut -d\| -f3 <<< "${l_output}" | sed '/^$/d' | wc -l) -gt 0 ]]; then
        echo "${l_output}"
    else
        if [[ "${l_retry_count}" -lt "${l_retry_max}" ]]; then
            sleep 0.2
            [[ -z "${l_retry_count}" ]] && l_retry_count=0
            let "l_retry_count++"
            fn_Mpris_Track_Metadata "${l_retry_count}"
        else
            echo ''
        fi
    fi

    # For Spotify, 'artUrl' (https://open.spotify.com/image/XXXX) can't get image directly, the real download link is 'https://i.scdn.co/image/XXXX'.

    # - For Spotify normal audio track
    # mpris|trackid|spotify:track:2F9xBxKbx2M0pbgtSu8fLf
    # mpris|length|320467000
    # mpris|artUrl|https://open.spotify.com/image/ab67616d00001e02149cf6977defe909fd7d34fd
    # xesam|album|Battlecry
    # xesam|albumArtist|Two Steps from Hell
    # xesam|artist|Two Steps from Hell
    # xesam|autoRating|0.64
    # xesam|discNumber|1
    # xesam|title|Victory
    # xesam|trackNumber|3
    # xesam|url|https://open.spotify.com/track/2F9xBxKbx2M0pbgtSu8fLf

    # - For Spotify Advertisement info:
    # mpris|trackid|spotify:ad:000000013e9e1dfc0000002034171a0d
    # mpris|length|19696000
    # mpris|artUrl|
    # xesam|album|
    # xesam|albumArtist|
    # xesam|artist|
    # xesam|autoRating|0
    # xesam|discNumber|0
    # xesam|title|Advertisement
    # xesam|trackNumber|0
    # xesam|url|https://open.spotify.com/ad/000000013e9e1dfc0000002034171a0d
}


#########  2-4 Pulse Audio Function #########
fn_Player_Sink_Volume_Control(){
    local l_is_silent="${1:-0}"
    local l_sink_mute_option="${2:-0}"

    if fn_CommandExistIfCheck 'pactl'; then

        # Pulse Audio Controls
        # https://wiki.archlinux.org/index.php/Spotify#pactl_(pulseaudio)

        if [[ -n $(fn_Player_Info_Metadata_Extraction) ]]; then
            local l_sink_choose_num=''
            l_sink_choose_num=$(fn_Player_Info_Metadata_Extraction 's')

            # - Sink Mute Toggle
            if [[ "${p_sink_volume_toggle}" -ne 0 || "${l_sink_mute_option}" -ne 0 ]]; then
                local l_is_muted=''
                l_is_muted=$(fn_Player_Info_Metadata_Extraction 'm')

                pactl set-sink-input-mute "${l_sink_choose_num}" toggle #mute/unmute toggle
                # pactl set-sink-input-volume "${l_sink_choose_num}" +5% #volume up by 5%
                # pactl set-sink-input-volume "${l_sink_choose_num}" -5% #volume down by 5%

                # - Solve polybar ipc module issue ([module/mpris-toggle-mute])
                # https://github.com/dietervanhoof/polybar-spotify-controls/issues/6
                # https://github.com/s0344/Spotify_for_polybar
                # https://github.com/s0344/Spotify_for_polybar/blob/master/playpause.sh

                local l_mute_type='unmute'

                # polybar configuration '[module/mpris-toggle-mute]'
                # 1 stands for playing (uf485 )
                # 2 stands for pause (uf466  )
                local l_polybar_toggle_mute_index=1

                if [[ "${l_is_muted,,}" == 'no' ]]; then
                    l_mute_type='mute'
                    l_polybar_toggle_mute_index=2
                fi

                polybar-msg hook mpris-toggle-mute "${l_polybar_toggle_mute_index}" &> /dev/null
                [[ "${l_is_silent}" -eq 0 ]] && fn_Notification "${l_mute_type^^}" "${player_app_name} Sink"

            # - Sink Volume Up/Down Seek
            elif [[ -n "${p_sink_volume_seek}" ]]; then
                # unicode fc5c ﱜ , fc5b ﱛ 
                # pactl set-sink-input-volume "${l_sink_choose_num}" 5% # volume set to 5%
                # pactl set-sink-input-volume "${l_sink_choose_num}" +5% #volume up by 5%
                # pactl set-sink-input-volume "${l_sink_choose_num}" -5% #volume down by 5%

                p_sink_volume_seek="${p_sink_volume_seek//%/}"

                pactl set-sink-input-volume "${l_sink_choose_num}" ${p_sink_volume_seek}%

                local l_sink_volume_current=''
                l_sink_volume_current=$(fn_Player_Info_Metadata_Extraction 'v')
                fn_Notification "Volume Seek ${p_sink_volume_seek}% to ${l_sink_volume_current}%" "Player ${player_app_name} Sink"
            fi

        fi

    else
        # Note: this method not work for Spotify official client, use pulseaudio command pactl to control it

        #dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Volume'

        # Set Volume (min 0.0 to max 1.0)
        #dbus-send --print-reply --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set string:'org.mpris.MediaPlayer2.Player' string:'Volume' variant:double:0.0
        #dbus-send --print-reply --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Set string:'org.mpris.MediaPlayer2.Player' string:'Volume' variant:double:1.0

        local l_current_volume=''
        l_current_volume=$(${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" org.freedesktop.DBus.Properties.Get string:"${mpris_interface}" string:'Volume' 2> /dev/null | sed -r -n '/variant/{s@.*([[:digit:]]+)@\1@g;p}')

        local l_volume_set='0.0'
        [[ "${l_current_volume}" -eq 0 ]] && l_volume_set='1.0'
        ${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" org.freedesktop.DBus.Properties.Set string:"${mpris_interface}" string:'Volume' variant:double:"${l_volume_set}" 1> /dev/null
    fi
}

#########  2-5 Spotify Relevant Function #########
fn_Spotify_Advertisement_Track_Mute(){
    # https://gist.github.com/neerajvashistha/a22045093b0d431e903e64e3a98cba5e#file-sp-L222
    local l_metadata_info=''
    l_metadata_info=$(fn_Mpris_Track_Metadata)
    # mpris|trackid|spotify:ad:000000013f8422900000002033f80d95
    # mpris|length|24999000
    # xesam|title|Advertisement

    local l_track_title=$(fn_Mpris_Track_Metadata_Extraction 'title' "${l_metadata_info}")

    if [[ "${l_track_title}" == 'Advertisement' ]]; then
        local l_track_id=$(fn_Mpris_Track_Metadata_Extraction 'trackid' "${l_metadata_info}")

        if [[ "${l_track_id}" =~ ^spotify:ad: ]]; then
            fn_Notification 'Advertisement time' "${player_app_name} Sink Mute"

            local l_mute_timeout=$(fn_Mpris_Track_Metadata_Extraction 'length' "${l_metadata_info}" | sed -r -n 's@^(.*?)[[:digit:]]{6}$@\1@g;p')
            ((l_mute_timeout++)) # plus 1 second

            fn_Player_Sink_Volume_Control '1' '1' # first 1 stands for silent output, second 1 stands for choose sink mute toggle function
            sleep ${l_mute_timeout}
            fn_Player_Sink_Volume_Control '1' '1'
            sleep 0.2
            fn_Spotify_Advertisement_Track_Mute
        fi
    fi
}

#########  2-6 MediaPlayer2 Track Position Function #########
fn_Player_Track_Position(){
    # Spotify official client not working

    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Position'
    #sed -r -n '/variant/{s@.*int[[:digit:]]+[[:space:]]*([[:digit:]]+)0{6}.*@\1@p}'

    # set position (microseconds)
    # https://github.com/popcornmix/omxplayer/issues/559
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.SetPosition objpath:'/3' int64:128000000
    # /3 is mpris:trackid from Metadata

    if [[ -n "${p_position_jump}" ]]; then
        local l_metadata_info=''
        l_metadata_info=$(fn_Mpris_Track_Metadata)
        local l_track_id=$(fn_Mpris_Track_Metadata_Extraction 'trackid' "${l_metadata_info}")
        local l_track_length=$(fn_Mpris_Track_Metadata_Extraction 'length' "${l_metadata_info}")

        local l_output=''
        l_output=$(${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" "${mpris_interface}".SetPosition objpath:"${l_track_id}" int64:${p_position_jump}000000 2>&1)

        if [[ -n "${l_output}" && "${l_output}" =~ [Ee]rror ]]; then
            fn_Notification "Fail to execute position action." "Player ${player_app_name}" 'critical'
        else
            fn_Notification "Position jump to ${p_position_jump} seconds" "Player ${player_app_name}"
        fi
    fi    
}

fn_Player_Track_Position_Seek(){
    # Spotify official client not working

    # seek (microseconds)
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Seek int64:8000000 # forward 8s
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Seek int64:-8000000 # backward 8s

    # [[ -n "${p_position_seek}" ]] && dbus-send --session --print-reply --dest=${mpris_bus_name} ${mpris_entry_point} ${mpris_interface}.Seek int64:${p_position_seek}000000

    local l_output=''

    if [[ -n "${p_position_seek}" ]]; then
        l_output=$(${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" "${mpris_interface}".Seek int64:${p_position_seek}000000)
        
        if [[ -n "${l_output}" && "${l_output}" =~ [Ee]rror ]]; then
            fn_Notification "Fail to execute seek action." "Player ${player_specify}" 'critical'
        else
            fn_Notification "Seek ${p_position_seek} seconds" "Player ${player_app_name}"
        fi
    fi
}

#########  3-1 MediaPlayer2 Playing Action Function #########
fn_Player_Playing_Status(){
    local l_disable_notification=${1:-0}

    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus'
    local l_play_status=''  # Playing|Paused|Stopped
    l_play_status=$(${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" org.freedesktop.DBus.Properties.Get string:"${mpris_interface}" string:'PlaybackStatus' 2> /dev/null | sed -r -n '/variant/{s@.*string[[:space:]]+"([^"]+).*@\1@g;p}')
    # Error org.freedesktop.DBus.Error.NoReply: Did not receive a reply. Possible causes include: the remote application did not send a reply, the message bus security policy blocked the reply, the reply timeout expired, or the network connection was broken.

    if [[ "${p_status_check}" -eq 1 ]]; then
        # fn_Notification "Status: ${l_play_status}" "${player_app_name}"
        echo -e "${l_play_status}\n${player_app_name}"
        exit
    fi

    local l_metadata_info=''
    l_metadata_info=$(fn_Mpris_Track_Metadata)
    local l_track_title=$(fn_Mpris_Track_Metadata_Extraction 'title' "${l_metadata_info}")

    if [[ -n "${l_track_title}" ]]; then
        local l_track_artist=$(fn_Mpris_Track_Metadata_Extraction 'artist' "${l_metadata_info}")
        local l_track_album=$(fn_Mpris_Track_Metadata_Extraction 'album' "${l_metadata_info}")

        # echo "${l_track_artist} - ${l_track_title} (${l_track_album})"

        local l_output=''
        [[ -n "${l_track_artist}" ]] && l_output="${l_track_artist}"
        if [[ -n "${l_track_title}" ]]; then
            [[ -n "${l_output}" ]] && l_output="${l_output} - ${l_track_title}" || l_output="${l_track_title}"
        fi

        if [[ -n "${l_track_album}" ]]; then
            [[ -n "${l_output}" ]] && l_output="${l_output} (${l_track_album})" || l_output="${l_track_album}"
        fi

        echo "${l_output}"
        # echo "${player_app_name}" >> "${p_session_save_path}"

        [[ "${l_disable_notification}" -eq 0 && -n "${l_output}" ]] && fn_Notification "${l_output}" "${player_app_name}"
    fi
}

fn_Player_Playing_Action_Method(){
    local l_method="${1:-}"

    case "${l_method,,}" in
        play ) l_method='Play' ;;
        pause ) l_method='Pause' ;;
        s|stop ) l_method='Stop' ;;
        n|next ) l_method='Next' ;;
        previous ) l_method='Previous' ;;
        toggle|playpause ) l_method='PlayPause' ;;
        # *) l_method='PlayPause' ;;
        *) l_method='' ;;
    esac

    [[ -n "${l_method}" ]] && ${dbus_send_comm} --dest="${mpris_bus_name}" "${mpris_entry_point}" "${mpris_interface}.${l_method}" &> /dev/null
}

fn_Player_Playing_Action(){
    # Play/Pause/PlayPause/Stop/Next/Previous

    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop

    # - Toogle Play/Pause
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause

    # - Next/Previous track
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
    # dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous

    # 80|no|no|100|Spotify|spotify  # sink num|corked (playpause)|is muted|volume|app name|binary name
    local l_sink_corked='' # no/yes
    l_sink_corked=$(fn_Player_Info_Metadata_Extraction 'c')
    # polybar configuration '[module/mpris-playpause]'
    # 1 stands for playing (uf8e3  ,uf8e5  ,uf28c )
    # 2 stands for pause (uf909 契 ,uf90c 奈 ,uf01d )
    local l_polybar_playpause_index=1


    if [[ -n "${p_action}" ]]; then
        local l_action_execute=${l_action_execute:-1}

        # Just for Spotify official client
        if [[ "${player_specify}" == 'spotify' ]]; then
            case "${p_action,,}" in
                previous)
                    fn_Player_Playing_Action_Method 'previous'
                ;;
                stop)
                    # 'no' stands for playing, 'yes' stands for pause playing

                    if [[ "${l_sink_corked}" == 'no' ]]; then
                        fn_Player_Playing_Action_Method 'previous'
                        
                        l_polybar_playpause_index=2
                        polybar-msg hook mpris-playpause "${l_polybar_playpause_index}" &> /dev/null
                    else
                        # Issue: As can't get current track play position from Spotify official client, If you player is Paused (l_sink_corked=='yes'), and position is at begin of the track, then the following command will play the latest previous track.
                        fn_Player_Playing_Action_Method 'previous'
                        l_action_execute=0
                    fi
                ;;
            esac
        fi

        if [[ "${l_action_execute}" -eq 1 ]]; then
            fn_Player_Playing_Action_Method "${p_action}"
            # fn_Notification "Status: ${p_action}" "Player ${player_specify}"
        fi

        case "${p_action,,}" in
            playpause )
                l_sink_corked=$(fn_Player_Info_Metadata_Extraction 'c')

                # 1 stands for playing (uf8e3  ,uf8e5  ,uf28c )
                # 2 stands for pause (uf909 契 ,uf90c 奈 ,uf01d )
                [[ "${l_sink_corked}" == 'no' ]] || l_polybar_playpause_index=2
                polybar-msg hook mpris-playpause "${l_polybar_playpause_index}" &> /dev/null
            ;;
            next|previous)
                # player will auto play, but web browser may be not.

                if [[ "${player_specify}" == 'spotify' ]]; then
                    sleep 0.2 # to make sure the following fn_Player_Playing_Status show current track
                    # - advertisement mute
                    fn_Spotify_Advertisement_Track_Mute
                else
                    # to fix track info still shows previous track info
                    sleep 0.4
                fi

                # polybar configuration '[module/mpris-playpause]'
                # 1 stands for playing (uf8e3 )
                polybar-msg hook mpris-playpause "${l_polybar_playpause_index}" &> /dev/null

                fn_Player_Playing_Status
            ;;
        esac


    else
        # For Chromium web browser, if player paused, its sink info will disappears from outputs of 'pactl list sink-inputs'. I haven't find parameter in 'chrome://flags/' similar to 'media.mediacontrol.stopcontrol.timer.ms' in Mozilla Firefox.

        # 1 stands for playing (uf8e3  ,uf8e5  ,uf28c )
        # 2 stands for pause (uf909 契 ,uf90c 奈 ,uf01d )
        [[ "${l_sink_corked}" == 'no' ]] || l_polybar_playpause_index=2
        polybar-msg hook mpris-playpause "${l_polybar_playpause_index}" &> /dev/null

        # fn_Player_Playing_Status '1'  # 1 stands for disable notification
        fn_Player_Playing_Status
    fi
}


#########  4-1 Entry Function #########

fn_Main(){
    fn_InitializationCheck
    fn_Mpris_DBus_Name_List
    fn_Mpris_Player_Choose

    if [[ "${p_track_metadata_list}" -ne 0 ]]; then
        fn_Mpris_Track_Metadata
        exit
    fi

    # Sink volume mute toggle/volume up/down seek
    if [[ "${p_sink_volume_toggle}" -ne 0 || -n "${p_sink_volume_seek}" ]]; then
        fn_Player_Sink_Volume_Control
        exit
    fi

    if [[ -n "${p_position_jump}" ]]; then
        fn_Player_Track_Position
        exit
    fi

    if [[ -n "${p_position_seek}" ]]; then
        fn_Player_Track_Position_Seek
        exit
    fi

    fn_Player_Playing_Action
}

fn_Main

# Script End
