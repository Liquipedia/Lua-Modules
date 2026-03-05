---
-- @Liquipedia
-- page=Module:Widget/WarningBox/Group
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local WarningBox = Lua.import('Module:Widget/WarningBox')

---@class WarningBoxGroupWidget: Widget
---@operator call(table): WarningBoxGroupWidget
---@field props {data: (string|number)[]?}
local WarningBoxGroupWidget = Class.new(Widget)

---@return Widget[]?
function WarningBoxGroupWidget:render()
	local data = self.props.data
	if Logic.isEmpty(data) then
		return
	end
	---@cast data -nil
	return Array.map(data, function (warning)
		return WarningBox{text = warning}
	end)
end

return WarningBoxGroupWidget
