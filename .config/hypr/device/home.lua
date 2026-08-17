local main_monitor = "desc:Samsung Electric Company Odyssey G75F HNTL201148"

return {
	main_monitor = main_monitor,
	secondary_monitor = main_monitor,

	monitors = {
		{
			output = main_monitor,
			mode = "5120x2160@179.99",
			position = "0x0",
			scale = 1,
			vrr = 3,
		},
	},
}
