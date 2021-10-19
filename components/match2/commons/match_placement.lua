---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match/Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TypeUtil = require('Module:TypeUtil')

local MatchPlacement = {propTypes = {}}

MatchPlacement.medalIcons = {
	'Gold.png',
	'Silver.png',
	'Bronze.png',
	'Copper.png',
	sf = 'SF.png',
}
MatchPlacement.medalTitles = {
	'First',
	'Second',
	'Third',
	'Fourth',
	sf = 'Semifinalist',
}

MatchPlacement.propTypes.MedalIcon = {
	place = 'number?',
	range = TypeUtil.optional(TypeUtil.array('number')),
}

--[[
Display component for a medal icon representing a placement or placement range.
]]
function MatchPlacement.MedalIcon(props)
	local place = props.range[1] or props.place
	if props.range and props.range[1] == 3 and props.range[2] == 4 then
		return mw.html.create('span')
			:attr('title', MatchPlacement.medalTitles.sf)
			:wikitext('[[File:' .. MatchPlacement.medalIcons.sf .. '|alt=]]')
	elseif 1 <= place and place <= 4 then
		return mw.html.create('span')
			:attr('title', MatchPlacement.medalTitles[place])
			:wikitext('[[File:' .. MatchPlacement.medalIcons[place] .. '|alt=]]')
	else
		return nil
	end
end

return MatchPlacement