---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/CountdownIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local PHASE_ICONS = {
	finished = {iconName = 'concluded', color = 'icon--green'},
	ongoing = {iconName = 'live', color = 'icon--red'},
	upcoming = {iconName = 'upcomingandongoing'},
}

---@param props {game: FFAMatchGroupUtilMatch|FFAMatchGroupUtilGame, additionalClasses: string[]?}
---@return Renderable
local function MatchSummaryFfaCountdownIcon(props)
	local iconData = PHASE_ICONS[MatchGroupUtil.computeMatchPhase(props.game)] or {}
	return IconWidget{
		iconName = iconData.iconName,
		color = iconData.color,
		additionalClasses = props.additionalClasses
	}
end

return Component.component(MatchSummaryFfaCountdownIcon)
