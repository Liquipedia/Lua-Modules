---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local OpponentLibrary = Lua.import('Module:OpponentLibraries')

return {
	Array = Lua.import('Module:Array'),
	Class = Lua.import('Module:Class'),
	Condition = Lua.import('Module:Condition'),
	DateExt = Lua.import('Module:Date/Ext'),
	Game = Lua.import('Module:Game'),
	I18n = Lua.import('Module:I18n'),
	Icon = Lua.import('Module:Icon'),
	Image = Lua.import('Module:Image'),
	Info = Lua.import('Module:Info'),
	Json = Lua.import('Module:Json'),
	Logic = Lua.import('Module:Logic'),
	Lpdb = Lua.import('Module:Lpdb'),
	Lua = Lua,
	Operator = Lua.import('Module:Operator'),
	Opponent = OpponentLibrary.Opponent,
	OpponentDisplay = OpponentLibrary.OpponentDisplay,
	Page = Lua.import('Module:Page'),
	String = Lua.import('Module:StringUtils'),
	Table = Lua.import('Module:Table'),
	Tier = Lua.import('Module:Tier'),
	Variables = Lua.import('Module:Variables'),
}
