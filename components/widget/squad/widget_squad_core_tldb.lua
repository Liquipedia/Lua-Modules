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

---@param status SquadStatus
---@return Widget
function SquadTldb:header(status)
	return Widgets.Tr{
		classes = {'HeaderRow'},
		cells = {
			Widgets.Th{children = {'ID'}},
			Widgets.Th{}, -- "Team Icon" (most commmonly used for loans)
			Widgets.Th{children = {'Name'}},
			Widgets.Th{children = {'ELO'}},
			Widgets.Th{children = {'ELO Peak'}},
		}
	}
end

---@param status SquadStatus
---@param title string?
---@return Widget?
function SquadTldb:_title(status, title)
	return nil
end

return SquadTldb
