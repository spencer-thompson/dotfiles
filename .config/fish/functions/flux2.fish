function poll_for_result -a flux_image_id

    set -l flux_pro_get_url "https://api.bfl.ai/v1/get_result?id=$flux_image_id"

    sleep 1

    while true
        set -l flux_result (gum spin -- curl --silent --request GET \
            --url "$flux_pro_get_url")

        # echo $flux_result | jq -r '.status'
        if test (echo $flux_result | jq -r '.status') = Ready
            set -l flux_download_url (echo $flux_result | jq -r '.result.sample')
            # echo $flux_download_url

            curl --silent $flux_download_url | tee flux_image.jpeg | chafa --scale max --align mid,mid -

            break
        end

    end
end

function flux2
    set -l opt_spec n/lines=
    set -a opt_spec "w/width=&"
    set -a opt_spec "h/height=&"
    set -a opt_spec "s/seed=&"
    argparse $opt_spec -- $argv || return

    set -l flux_width 1024
    set -l flux_height 1024

    if set -q _flag_width
        echo $_flag_width
        set -l flux_width $_flag_width
    end

    if set -q _flag_height
        echo $_flag_height
        set -l flux_height $_flag_height
    end

    set -f input_image_1

    if gum confirm --default "Add an image?"
        set -f input_image_1 (base64 (fd '.*\.(png|jpe?g)$' | fzf --preview='test -f {} && file --mime-type {} | grep -q "image/" && kitty +kitten icat --clear --stdin=no --transfer-mode=memory --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES"@0x0 {}' --preview-window "top,20" --height=50%))
        kitten icat --clear
    end

    set -l flux_prompt (gum write --value "$flux_last_prompt" --placeholder "Subject + Action + Style + Context" --height=3)
    set -g flux_last_prompt "$flux_prompt"

    set -l flux_payload \
        (printf "%s" "$input_image_1" | jq -Rn \
            --arg p "$flux_prompt"\
            --argjson w $flux_width \
            --argjson h $flux_height \
            --argjson s 5 \
            '{prompt: $p, safety_tolerance: $s, width: $w, height: $h, input_image: input}')

    echo "$flux_payload" \
        | curl --silent --request POST \
        --url https://api.bfl.ai/v1/flux-2-pro \
        --header 'Content-Type: application/json' \
        --header "x-key: $BFL_API_KEY" \
        --data @- \
        | jq -r ".id, .polling_url, .cost" \
        | read -l flux_image_id flux_polling_url flux_cost

    # set -l flux_image_id 25d725be-6f9e-48a2-aded-14fdfbcf3672

    # echo $flux_cost

    # set -l flux_generated_image_id \
    #     (jq -n --arg i "$flux_image_id" '{id: $i}')

    # echo $flux_polling_url
    echo $flux_image_id

    poll_for_result $flux_image_id

    gum spin -- curl --silent --request GET \
        --url https://api.bfl.ai/v1/credits \
        --header "x-key: $BFL_API_KEY" \
        | jq -r '.credits'

end
