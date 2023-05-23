---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox', {requireDevIfEnabled = true})

local CustomHiddenDataBox = {}

---@param args table
---@return string
function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	BasicHiddenDataBox.checkAndAssign(
		'tournament_publishertier',
		args.pokemonpremier,
		queryResult.publishertier
	)
end

return Class.export(CustomHiddenDataBox)
