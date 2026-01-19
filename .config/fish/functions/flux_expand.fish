function flux_expand

    # set -l flux_prompt (gum write --value "$flux_last_prompt" --placeholder "Subject + Action + Style + Context" --height=3)
    # set -g flux_last_prompt "$flux_prompt"

    set -f input_image_1 (base64 (fd '.*\.(png|jpe?g)$' | fzf --preview='test -f {} && file --mime-type {} | grep -q "image/" && kitty +kitten icat --clear --stdin=no --transfer-mode=memory --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES"@0x0 {}' --preview-window "top,20" --height=50%))
    kitten icat --clear

    set -l flux_payload \
        (printf "%s" "$input_image_1" | jq -Rn \
            # --arg p "$flux_prompt"\
            --argjson t 0 \
            --argjson b 0 \
            --argjson l 200 \
            --argjson r 200 \
            --argjson s 6 \
            '{safety_tolerance: $s, top: $t, bottom: $b, left: $l, right: $r, image: input}')

    echo "$flux_payload" \
        | curl --silent --request POST \
        --url "https://api.bfl.ai/v1/flux-pro-1.0-expand" \
        --header 'Content-Type: application/json' \
        --header "x-key: $BFL_API_KEY" \
        --data @- \
        | jq -r ".id" \
        | read -l flux_image_id

    # set -l flux_image_id 25d725be-6f9e-48a2-aded-14fdfbcf3672

    # echo $flux_cost

    # set -l flux_generated_image_id \
    #     (jq -n --arg i "$flux_image_id" '{id: $i}')

    # echo $flux_polling_url
    echo $flux_image_id

    gum spin -- flux_poll_for_result $flux_image_id

    gum spin -- curl --silent --request GET \
        --url https://api.bfl.ai/v1/credits \
        --header "x-key: $BFL_API_KEY" \
        | jq -r '.credits'
end
