---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Trophy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local TROPHY_COLOR = {
	'icon--gold',
	'icon--silver',
	'icon--bronze',
	'icon--copper',
}

---@param props {place: integer, additionalClasses?: string[]}
---@return HtmlNode?
local function MatchSummaryFfaTrophy(props)
	if not TROPHY_COLOR[props.place] then
		return
	end
	return IconWidget{
		iconName = 'firstplace',
		additionalClasses = Array.extend(props.additionalClasses, TROPHY_COLOR[props.place])
	}
end

return Component.component(MatchSummaryFfaTrophy)
