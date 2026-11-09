--- Triple Comment to Enable our LLS Plugin
insulate('Widget/Legend', function()
	it('integration', function()
		local LegendComponent = require('Module:Widget/Legend')

		GoldenTest('standings_legend', tostring(LegendComponent{
			byeup = 'Lorem ipsum byeup',
			seedup = 'Lorem ipsum seedup',
			up = 'Lorem ipsum up',
			stayup = 'Lorem ipsum stayup',
			stay = 'Lorem ipsum stay',
			staydown = 'Lorem ipsum staydown',
			down = 'Lorem ipsum down',
			points = 'Lorem ipsum points',
			showMinimum = true,
			showNumberSection = true,
		}))
	end)

	it('reads the template input into types', function()
		local WidgetFactory = require('Module:Widget/Factory')
		local legend = tostring(WidgetFactory.fromTemplate{
			widget = 'Legend',
			showNumberSection = 'true',
			showConfirmed = 'false',
			showMinimum = '',
		})
		assert.is_falsy(legend:find('Placement confirmed', 1, true))
		assert.is_falsy(legend:find('Minimum placement reached', 1, true))
		assert.is_truthy(legend:find('Placement undecided', 1, true))
	end)

	it('documents the parameters', function()
		local ArgSchemaDocumentation = require('Module:ArgSchema/Documentation')
		local originalPreprocess = mw.frame.preprocess
		mw.frame.preprocess = function(_, text) return text end
		local documentation = tostring(ArgSchemaDocumentation.parameters{schema = 'Widget/Legend'})
		mw.frame.preprocess = originalPreprocess
		assert.is_truthy(documentation:find('&#124;showConfirmed&#61;true', 1, true))
	end)
end)
