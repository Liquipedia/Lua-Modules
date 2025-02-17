---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/CountdownIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Widget = Lua.import('Module:Widget')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchSummaryFfaCountdownIcon: Widget
---@operator call(table): MatchSummaryFfaCountdownIcon
local MatchSummaryFfaCountdownIcon = Class.new(Widget)

local PHASE_ICONS = {
	finished = {iconName = 'concluded', color = 'icon--green'},
	ongoing = {iconName = 'live', color = 'icon--red'},
	upcoming = {iconName = 'upcomingandongoing'},
}

---@return Widget
function MatchSummaryFfaCountdownIcon:render()
	local iconData = PHASE_ICONS[MatchGroupUtil.computeMatchPhase(self.props.game)] or {}
	return IconWidget{
		iconName = iconData.iconName,
		color = iconData.color,
		additionalClasses = self.props.additionalClasses
	}
end

return MatchSummaryFfaCountdownIcon
