hl.curve("auto_default", {
	type = "bezier",
	points = {
		{ 0.05, 0.9 },
		{ 0.1, 1.05 },
	},
})

-- hl.curve("rubber", {
-- 	type = "spring",
-- 	mass = 1,
-- 	stiffness = 70,
-- 	dampening = 10,
-- })
hl.curve("rubber", { type = "spring", mass = 1, stiffness = 70, dampening = 12 })
hl.curve("damp", { type = "spring", mass = 1, stiffness = 100, dampening = 20 })

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

hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "rubber", style = "gnomed" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "damp", style = "gnomed" })
-- hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, spring = "damp", style = "popin 66%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, spring = "damp", style = "gnomed" })
-- hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default", style = "gnomed" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "default", style = "slide" })
-- hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "default", style = "fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, spring = "rubber", style = "fade" })
-- hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "border", enabled = true, speed = 1, spring = "rubber" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 40, bezier = "linear", style = "once" })
-- hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "default" })
-- hl.animation({ leaf = "fadeGlow", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slide" })
-- hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3, bezier = "default", style = "slide" })
-- hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "default", style = "slidefade" })
-- hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "default", style = "slidevert" })
