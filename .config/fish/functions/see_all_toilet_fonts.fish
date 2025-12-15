function see_all_toilet_fonts
    for font in "(ls -1 /usr/share/figlet/ | sed -r '/_/d; s/\..*//')"
        echo $font
        toilet -f "$font" -F rainbow Spencer
    end
end
