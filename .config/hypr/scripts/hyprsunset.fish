if pgrep -x hyprsunset >/dev/null
    notify-send -a Hyprsunset -i night-light-disabled-symbolic "Stopping Hyprsunset..."
    pkill -x hyprsunset
else
    notify-send -a Hyprsunset -i night-light-symbolic "Starting Hyprsunset..."
    hyprsunset --temperature 3000 --gamma 40
end
