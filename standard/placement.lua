---
-- @Liquipedia
-- wiki=commons
-- page=Module:Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Ordinal = require('Module:Ordinal')

local Placement = {}

--[[
Returns a text label for a range of placements.

Example:
Placement.RangeLabel({1, 2})
-- Returns 1st–2nd
]]
function Placement.RangeLabel(range)
	local zeroWidthSpace = '&#8203;'
	local enDash = '–'
	return table.concat({
		Ordinal._ordinal(range[1]),
		range[1] < range[2] and Ordinal._ordinal(range[2]) or nil,
	}, zeroWidthSpace .. enDash .. zeroWidthSpace)
end

Placement.placementClasses = {
	'background-color-first-place',
	'background-color-second-place',
	'background-color-third-place',
	'background-color-fourth-place',
	w = 'bg-win',
	d = 'bg-draw',
	l = 'bg-lose',
	dq = 'bg-dq',
}

--[[
Converts a placement to a css class that sets its background.

Example:
Placement.getBgClass(2)
-- returns 'background-color-second-place'
]]
function Placement.getBgClass(placement)
	return Placement.placementClasses[placement]
end

local ordinalSuffix = {
	['1'] = 'st',
	['2'] = 'nd',
	['3'] = 'rd',
	['4'] = 'th',
	['5'] = 'th',
	['6'] = 'th',
	['7'] = 'th',
	['8'] = 'th',
	['9'] = 'th',
	['0'] = 'th',
	['11'] = 'th',
	['12'] = 'th',
	['13'] = 'th',
}

local placeSortPrefix = {
	['1'] = 'A',
	['2'] = 'B',
	['3'] = 'C',
	['4'] = 'D',
	['5'] = 'E',
	['6'] = 'F',
	['7'] = 'G',
	['8'] = 'H',
	['9'] = 'I',
	['10'] = 'J',
	['11'] = 'K',
	['12'] = 'L',
	['13'] = 'M',
	['14'] = 'N',
	['15'] = 'O',
	['16'] = 'P',
	['17'] = 'Q',
	['w'] = 'T1',
	['l'] = 'T2',
	['dq'] = 'T3',
	['dnp'] = 'V',
	['proceeded'] = 'W1',
	['stay'] = 'W2',
	['relegated'] = 'W3',
}

local placeColorClass = {
	['1'] = 'placement-1',
	['2'] = 'placement-2',
	['3'] = 'placement-3',
	['4'] = 'placement-4',
	['5'] = 'placement-lightblue',
	['6'] = 'placement-lightblue',
	['7'] = 'placement-lightblue',
	['8'] = 'placement-lightblue',
	['9'] = 'placement-blue',
	['10'] = 'placement-blue',
	['11'] = 'placement-blue',
	['12'] = 'placement-blue',
	['13'] = 'placement-blue',
	['14'] = 'placement-blue',
	['15'] = 'placement-blue',
	['16'] = 'placement-blue',
	['32'] = 'placement-darkblue',
	['256'] = 'placement-darkgrey',
	['w'] = 'placement-win',
	['l'] = 'placement-lose',
	['dq'] = 'placement-lose',
	['dnp'] = 'placement-dnp',
	['proceeded'] = 'placement-up',
	['stay'] = 'placement-stay',
	['relegated'] = 'placement-down',
}

local textColor = {
	-- White is the default color. Only overrides will need to be entered here.
	['dnp'] = 'black',
}

local skipShadow = {
	-- Default is false
	['dnp'] = true,
}

function Placement._placement(args)
	-- Defaults
	local textColorCell = 'white'
	local skipShadowCell = false

	-- Attempt to split the placement into two parts and store it in a table
	local placement = mw.text.split(tostring(args.placement), '-', true)

	-- If the table has 2 parts, the placement has a start and end number
	local text
	local diff
	if tonumber(placement[1]) == nil then
		text = string.upper(placement[1])
		diff = 0
	elseif table.maxn(placement) == 2 then
		if ordinalSuffix[placement[2]] then
			text = placement[1] .. '&nbsp;-&nbsp;' .. placement[2] .. ordinalSuffix[placement[2]]
		else
			text = placement[1] .. '&nbsp;-&nbsp;' .. placement[2] .. ordinalSuffix[string.sub(placement[2], -1)]
		end
		diff = (tonumber(placement[2]) or 1000) - tonumber(placement[1])
	else
		if ordinalSuffix[placement[1]] then
			text = placement[1] .. ordinalSuffix[placement[1]]
		else
			text = placement[1] .. ordinalSuffix[string.sub(placement[1], -1)]
		end
		diff = 0
	end

	-- Cell color
	if tonumber(placement[1]) ~= nil then
		if tonumber(placement[1]) <= 16 then
			args.parent:addClass(placeColorClass[placement[1]])
			textColorCell = textColor[placement[1]] or textColorCell
			skipShadowCell = skipShadow[placement[1]] or skipShadowCell
		elseif tonumber(placement[1]) <= 32 then
			args.parent:addClass(placeColorClass['32'])
			textColorCell = textColor['32'] or textColorCell
			skipShadowCell = skipShadow['32'] or skipShadowCell
		else
			args.parent:addClass(placeColorClass['256'])
			textColorCell = textColor['256'] or textColorCell
			skipShadowCell = skipShadow['256'] or skipShadowCell
		end
	else
		args.parent:addClass(placeColorClass[placement[1]])
		textColorCell = textColor[placement[1]] or textColorCell
		skipShadowCell = skipShadow[placement[1]] or skipShadowCell
	end

	-- Parent attributes
	args.parent:attr('align', 'center')

	-- HiddenSort
	local sortPrefix --Sort key for first part
	if tonumber(placement[1]) ~= nil then
		if tonumber(placement[1]) <= 17 then
			sortPrefix = placeSortPrefix[placement[1]]
		elseif tonumber(placement[1]) <= 32 then
			sortPrefix = 'R'
		else
			sortPrefix = 'S'
		end
	elseif placement[1] ~= nil then
		sortPrefix = placeSortPrefix[placement[1]]
	else
		sortPrefix = 'Z'
	end

	local sortPrefix2 --Sort key for second part
	if tonumber(diff) == 0 then
		sortPrefix2 = ''
	elseif tonumber(diff) <= 17 then
		sortPrefix2 = placeSortPrefix[tostring(diff)]
	elseif tonumber(diff) <= 32 then
		sortPrefix2 = 'R'
	else
		sortPrefix2 = 'S'
	end

	if sortPrefix == nil then
		mw.log('No placement found in Module:Placement: ' .. args.placement)
		args.parent:attr('data-sort-value', 'ZZ')
		args.parent:tag('font')
			:wikitext(args.placement .. ' [[Category:Pages with unknown placements]]')
	else
		args.parent:attr('data-sort-value', sortPrefix .. sortPrefix2)

		-- Display text
		args.parent:tag('font')
			:addClass(not skipShadowCell and 'placement-text' or nil)
			:css('font-weight', 'bold')
			:css('color', textColorCell)
			:wikitext(text .. (args.text and ' ' .. args.text or ''))
	end
end

function Placement.placement(frame)
	return Placement._placement(Arguments.getArgs(frame))
end

return Class.export(Placement)
