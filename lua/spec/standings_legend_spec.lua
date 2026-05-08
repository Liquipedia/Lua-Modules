--- Triple Comment to Enable our LLS Plugin
insulate('Widget/Legend', function()
	it('integration', function()
		local LegendComponent = require('Module:Widget/Legend')

		GoldenTest('standings_legend', tostring(LegendComponent{
		color = {
			byeup = 'Lorem ipsum',
			seedup = 'Lorem ipsum',
			up = 'Lorem ipsum',
			stayup = 'Lorem ipsum',
			stay = 'Lorem ipsum',
			staydown = 'Lorem ipsum',
			down = 'Lorem ipsum',
		},
		points = {'Lorem ipsum'},
		showMinimum = true,
		showNumberSection = true,
	}))
	end)
end)
