local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Tabs = Lua.import('Module:Tabs')

local TransferTabs = {}

function TransferTabs.run(args)
	args = args or {}
	local currentYear = os.date('%Y')
	Array.forEach(Array.range(2010, currentYear), function(year)
		local index = year - 2009
		args['name' .. index] = year
		args['link' .. index] = 'Player Transfers/' .. year
	end)

	return Tabs.static(args)
end

return Class.export(TransferTabs)
