---
-- @Liquipedia
-- page=Module:Widget/Infobox/Series/Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local Widget = Lua.import('Module:Widget')

---@class InfoboxSeriesIconWidget: Widget
---@operator call(table):InfoboxSeriesIconWidget
---@field displayManualIcons boolean
---@field series string?
---@field abbreviation string?
---@field icon string?
---@field iconDark string?
---@field endDate string?
local SeriesIcon = Class.new(Widget)

---@return string
function SeriesIcon:render()
	local props = self.props

	if Logic.isEmpty(props.series) then
		return ''
	end
	local series = props.series
	---@cast series -nil

	local output = LeagueIcon.display{
		icon = props.displayManualIcons and props.icon or nil,
		iconDark = props.displayManualIcons and props.iconDark or nil,
		series = series,
		abbreviation = props.abbreviation,
		date = self.props.endDate,
		options = {noLink = not Page.exists(series)}
	}

	return output == LeagueIcon.display{} and '' or output
end

return SeriesIcon
