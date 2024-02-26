---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.game = Game.name{game = args.game}

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	BasicHiddenDataBox.checkAndAssign(
		'tournament_publishertier',
		args.publisherpremier and tostring(Logic.readBool(args.publisherpremier)) or nil,
		queryResult.publishertier
	)
end

return Class.export(CustomHiddenDataBox)
