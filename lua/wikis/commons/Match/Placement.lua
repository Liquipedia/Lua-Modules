---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match/Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchPlacement = {}

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

---Display component for a medal icon representing a placement or placement range.
---@param props {place: number?, range: number[]?}
---@return Html?
function MatchPlacement.MedalIcon(props)
	local place = props.range[1] or props.place
	if props.range and props.range[1] == 3 and props.range[2] == 4 then
		return mw.html.create('span')
			:attr('title', MatchPlacement.medalTitles.sf)
			:wikitext('[[File:' .. MatchPlacement.medalIcons.sf .. '|alt=|link=]]')
	elseif 1 <= place and place <= 4 then
		return mw.html.create('span')
			:attr('title', MatchPlacement.medalTitles[place])
			:wikitext('[[File:' .. MatchPlacement.medalIcons[place] .. '|alt=|link=]]')
	else
		return nil
	end
end

return MatchPlacement
