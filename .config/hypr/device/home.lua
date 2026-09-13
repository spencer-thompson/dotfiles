local programs = require("modules.programs")
local main_monitor = "desc:Samsung Electric Company Odyssey G75F HNTL201148"

return {
    main_monitor = main_monitor,
    secondary_monitor = main_monitor,
    config = {
        cursor = {
            no_hardware_cursors = 2,
        },
        debug = {
            disable_logs = false,
            disable_time = false,
        },
        render = {
            new_render_scheduling = true,
        },
    },

    monitors = {
        {
            output = main_monitor,
            mode = "5120x2160@179.99",
            -- mode = "1920x1080@60",
            position = "0x0",
            scale = 1,
            bitdepth = 10,
            -- bitdepth = 8,
            cm = "auto",
            vrr = 3,
            -- vrr = 0,
        },
    },

    startup = {
        {
            command = programs.browser,
            rules = { workspace = "1 silent" },
        },
    },
}
