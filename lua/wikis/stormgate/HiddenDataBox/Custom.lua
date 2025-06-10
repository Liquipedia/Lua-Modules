---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.game = Game.name{game = args.game}

	return BasicHiddenDataBox.run(args)
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
