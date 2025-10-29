---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Trophy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchSummaryFfaTrophy: Widget
---@operator call(table): MatchSummaryFfaTrophy
local MatchSummaryFfaTrophy = Class.new(Widget)
MatchSummaryFfaTrophy.defaultProps = {
	additionalClasses = {},
}

local TROPHY_COLOR = {
	'icon--gold',
	'icon--silver',
	'icon--bronze',
	'icon--copper',
}

---@return Widget?
function MatchSummaryFfaTrophy:render()
	if not TROPHY_COLOR[self.props.place] then
		return nil
	end
	return IconWidget{
		iconName = 'firstplace',
		additionalClasses = Array.extend(self.props.additionalClasses, TROPHY_COLOR[self.props.place])
	}
end

return MatchSummaryFfaTrophy
