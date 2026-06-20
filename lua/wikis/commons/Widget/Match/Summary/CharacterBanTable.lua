---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/CharacterBanTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Icon = Lua.import('Module:Icon')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Characters = Lua.import('Module:Widget/Match/Summary/Characters')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local WidgetUtil = Lua.import('Module:Widget/Util')

local defaultProps = {
	flipped = false,
}

local ICONS = {
	left = Icon.makeIcon{iconName = 'startleft', size = '110%'},
	right = Icon.makeIcon{iconName = 'startright', size = '110%'},
	empty = Html.Span{},
}

---@param props {bans: {[1]: string[]?, [2]: string[]?, start: integer?, label: string?}[], date: string?}
---@return VNode?
local function MatchSummaryCharacterBanTable(props)
	if Logic.isDeepEmpty(props.bans) then
		return nil
	end

	local hasStartIndicator = Array.any(props.bans, function(banData)
		return Logic.isNotEmpty(banData.start)
	end)

	---@param teamIndex integer
	---@param startIndex integer
	---@return string
	local startIndicator = function(teamIndex, startIndex)
		if teamIndex ~= startIndex then
			return ICONS.empty
		elseif teamIndex == 1 then
			return ICONS.left
		end
		return ICONS.right
	end

	return GeneralCollapsible{
		classes = {'brkts-popup-veto-wrapper'},
		shouldCollapse = true,
		collapseAreaClasses = {'brkts-popup-veto'},
		titleClasses = {'brkts-popup-veto-header'};
		title = 'Bans',
		children = Array.map(props.bans, function(banData, gameNumber)
			if Logic.isDeepEmpty(banData) then
				return nil
			end
			return Div{
				classes = {'brkts-popup-veto-row'},
				children = WidgetUtil.collect(
					Characters{characters = banData[1], flipped = false, date = props.date},
					Div{
						classes = hasStartIndicator and {'brkts-popup-veto-row-indicator'} or nil,
						children = WidgetUtil.collect(
							hasStartIndicator and startIndicator(1, banData.start) or nil,
							banData.label or 'Game&nbsp;' .. gameNumber,
							hasStartIndicator and startIndicator(2, banData.start) or nil
						)
					},
					Characters{characters = banData[2], flipped = true, date = props.date}
				),
			}
		end)
	}
end

return Component.component(MatchSummaryCharacterBanTable, defaultProps)
