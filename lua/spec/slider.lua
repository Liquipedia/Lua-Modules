--- Triple Comment to Enable our LLS Plugin
local Slider = require('Module:Widget/Basic/Slider')

insulate('Slider', function()
	GoldenTest('Slider', Slider{
		id = 'test-slider',
		min = 0,
		max = 10,
		step = 2,
		defaultValue = 4,
		title = function(value) return 'Title ' .. value end,
		childrenAtValue = function(value)
			return 'Child ' .. value
		end,
	})
end)
