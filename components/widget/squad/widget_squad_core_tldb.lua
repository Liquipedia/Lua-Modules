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
---@return WidgetTableRowNew
function SquadTldb._header(type)
	return Widgets.TableRowNew{
		classes = {'HeaderRow'},
		cells = {
			Widgets.TableCellNew{content = {'ID'}, header = true},
			Widgets.TableCellNew{header = true}, -- "Team Icon" (most commmonly used for loans)
			Widgets.TableCellNew{content = {'Name'}, header = true},
			Widgets.TableCellNew{content = {'ELO'}, header = true},
			Widgets.TableCellNew{content = {'ELO Peak'}, header = true},
		}
	}
end

---@param type SquadType
---@param title string?
---@return WidgetTableRowNew?
function SquadTldb._title(type, title)
	return nil
end

return SquadTldb
