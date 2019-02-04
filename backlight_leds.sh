#!/bin/bash
leds(){
    case $1 in
        off)
	        blinkstick --set-color=off --morph --duration=500
	        if $2; then
	            notify-send 'Luce Spenta' -i /usr/share/icons/breeze/preferences/32/preferences-desktop-color.svg
		    fi
		    ;;
	    on)
		    if $2; then
		        notify-send 'Luce Accesa' -i /usr/share/icons/breeze/preferences/32/preferences-desktop-color.svg
            fi
            blinkstick --set-color=ff4f2c --morph --duration=500
			;;
	esac
}
screen_on(){
    #return true if screen is on
    xset -q | grep "Monitor is On\|DPMS is Disabled" > /dev/null
    local res=$?
    return "$res"
}
session_on(){
    #return true if sceensaver of the session is off
    dbus-send --session --dest=org.freedesktop.ScreenSaver --type=method_call --print-reply /org/freedesktop/ScreenSaver org.freedesktop.ScreenSaver.GetActive | grep "boolean false" > /dev/null
    local res=$?
    return "$res"
}
user_on(){
    #return true if session is active
    loginctl show-session -p Active "$(loginctl list-sessions --no-legend | grep "$USER" | awk '{ print $1 }')" | grep yes > /dev/null
    local res=$?
    return "$res"
}
daemon(){
    echo "$$" > "$PID"
    first=true
    while :
    do
        while ! user_on :
        do
                sleep 1
        done
        if screen_on && session_on; then
            leds on "$first"
            first=false
            while screen_on && session_on :
            do
                sleep 1
            done
        fi
        leds off "false"
        sleep 1
        #else
        #    leds off "false"
        #fi
        #sleep 1
    done
    #loop_screen &
    #if session_on && screen_on; then
    #    leds on $first
    #    first=false
    #fi
    #dbus-monitor --session "type='signal',interface='org.freedesktop.ScreenSaver'" |
    #while read -r x; do
    #    case "$x" in
    #        *"boolean true"*)
    #            leds off "false"
    #            ;;
    #        *"boolean false"*) 
    #            leds on $first
    #            first=false
    #            ;;  
    #    esac
    #done
}
PID=/home/"$USER"/.led.pid
if [ -f "$PID" ]; then
    if ps -p "$(<"$PID")" > /dev/null; then
        kill -9 "$(<"$PID")"
        leds off "true"
        rm "$PID"
    else
        daemon
    fi
else
    daemon
fi
