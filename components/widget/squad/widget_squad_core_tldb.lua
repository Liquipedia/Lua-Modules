---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Squad/Core/Tldb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widgets = Lua.import('Module:Widget/All')
local SquadWidget = Lua.import('Module:Widget/Squad/Core')

---@class SquadTldbWidget: SquadWidget
---@operator call:SquadTldbWidget
local SquadTldb = Class.new(SquadWidget)

---@param type SquadType
---@return WidgetTr
function SquadTldb._header(type)
	return Widgets.Tr{
		classes = {'HeaderRow'},
		cells = {
			Widgets.Th{content = {'ID'}},
			Widgets.Th{}, -- "Team Icon" (most commmonly used for loans)
			Widgets.Th{content = {'Name'}},
			Widgets.Th{content = {'ELO'}},
			Widgets.Th{content = {'ELO Peak'}},
		}
	}
end

---@param type SquadType
---@param title string?
---@return WidgetTr?
function SquadTldb._title(type, title)
	return nil
end

return SquadTldb
