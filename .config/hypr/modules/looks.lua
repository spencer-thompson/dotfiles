hl.curve("auto_default", {
	type = "bezier",
	points = {
		{ 0.05, 0.9 },
		{ 0.1, 1.05 },
	},
})

hl.curve("linear", {
	type = "bezier",
	points = {
		{ 0.0, 0.0 },
		{ 1.0, 1.0 },
	},
})

hl.curve("custom", {
	type = "bezier",
	points = {
		{ 0.05, 0.95 },
		{ 0.05, 1.1 },
	},
})

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "auto_default", style = "popin" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "custom", style = "popin 50%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "custom", style = "popin 50%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "default", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "default", style = "fade" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 40, bezier = "linear", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3, bezier = "default", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "default", style = "slidefade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "default", style = "slidevert" })
