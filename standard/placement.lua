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

local placeColor = {
	['1'] = '#FFD739',
	['2'] = '#BEBEBE',
	['3'] = '#BB8644',
	['4'] = '#F8996B',
	['5'] = '#007F99',
	['6'] = '#007F99',
	['7'] = '#007F99',
	['8'] = '#007F99',
	['9'] = '#166F82',
	['10'] = '#166F82',
	['11'] = '#166F82',
	['12'] = '#166F82',
	['13'] = '#166F82',
	['14'] = '#166F82',
	['15'] = '#166F82',
	['16'] = '#166F82',
	['32'] = '#2D606B',
	['256'] = '#445154',
	['w'] = '#009E60',
	['l'] = '#dddddd',
	['dq'] = '#dddddd',
	['dnp'] = '#d0d0d0',
	['proceeded'] = '#89E069',
	['stay'] = '#FEDE68',
	['relegated'] = '#FF6F6F',
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
		diff = 1
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
		diff = 1
	end

	-- Cell color
	if tonumber(placement[1]) ~= nil then
		if tonumber(placement[1]) <= 16 then
			args.parent:attr('bgcolor', placeColor[placement[1]])
			textColorCell = textColor[placement[1]] or textColorCell
			skipShadowCell = skipShadow[placement[1]] or skipShadowCell
		elseif tonumber(placement[1]) <= 32 then
			args.parent:attr('bgcolor', placeColor['32'])
			textColorCell = textColor['32'] or textColorCell
			skipShadowCell = skipShadow['32'] or skipShadowCell
		else
			args.parent:attr('bgcolor', placeColor['256'])
			textColorCell = textColor['256'] or textColorCell
			skipShadowCell = skipShadow['256'] or skipShadowCell
		end
	else
		args.parent:attr('bgcolor', placeColor[placement[1]])
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
	if tonumber(diff) <= 17 then
		sortPrefix2 = placeSortPrefix[tostring(diff)]
	elseif tonumber(diff) <= 32 then
		sortPrefix2 = 'R'
	else
		sortPrefix2 = 'S'
	end

	if sortPrefix == nil then
		mw.log('No placement found in Module:Placement: ' .. args.placement)
		args.parent:tag('span')
			:css('display', 'none')
			:wikitext('ZZ')
		args.parent:tag('font')
			:wikitext(args.placement .. ' [[Category:Pages with unknown placements]]')
	else
		args.parent:tag('span')
			:css('display', 'none')
			:wikitext(sortPrefix .. sortPrefix2)

		-- Display text
		args.parent:tag('font')
			:addClass('placement-text')
			-- luacheck: ignore
			-- line length
			:css('text-shadow', (skipShadowCell and 'none' or '1px 1px rgba(64, 64, 64, 0.4), 1px -1px rgba(64, 64, 64, 0.4), -1px -1px rgba(64, 64, 64, 0.4), -1px 1px rgba(64, 64, 64, 0.4)'))
			:css('font-weight', 'bold')
			:css('color', textColorCell)
			:wikitext(text .. (args.text and ' ' .. args.text or ''))
	end
end

function Placement.placement(frame)
	return Placement._placement(Arguments.getArgs(frame))
end

return Class.export(Placement)
