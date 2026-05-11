--- Triple Comment to Enable our LLS Plugin
insulate('Widget/Legend', function()
	it('integration', function()
		local LegendComponent = require('Module:Widget/Legend')

		GoldenTest('standings_legend', tostring(LegendComponent{
		color = {
			byeup = 'Lorem ipsum byeup',
			seedup = 'Lorem ipsum seedup',
			up = 'Lorem ipsum up',
			stayup = 'Lorem ipsum stayup',
			stay = 'Lorem ipsum stay',
			staydown = 'Lorem ipsum staydown',
			down = 'Lorem ipsum down',
		},
		points = {'Lorem ipsum points'},
		showMinimum = true,
		showNumberSection = true,
	}))
	end)
end)
