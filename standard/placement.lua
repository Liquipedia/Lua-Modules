---
-- @Liquipedia
-- wiki=commons
-- page=Module:Placement
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Ordinal = require('Module:Ordinal')
local Table = require('Module:Table')

local Placement = {}

local ZERO_WIDTH_SPACE = '&#8203;'
local EN_DASH = '–'

local PLACEMENT_CLASSES = {
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
	['17'] = 'placement-darkblue',
	['129'] = 'placement-darkgrey',
	['q'] = 'placement-win',
	['w'] = 'placement-win',
	['d'] = 'placement-draw',
	['l'] = 'placement-lose',
	['dq'] = 'placement-lose',
	['dnp'] = 'placement-dnp',
	['proceeded'] = 'placement-up',
	['stay'] = 'placement-stay',
	['relegated'] = 'placement-down',
	['div'] = 'placement-darkgrey',
}

local CUSTOM_SORTS = {
	['w'] = '1025',
	['proceeded'] = '1026',
	['q'] = '1027',
	['d'] = '1028',
	['stay'] = '1029',
	['l'] = '1030',
	['relegated'] = '1031',
	['dnp'] = '1032',
	['dq'] = '1033',
	['div'] = '1034',
	[''] = '1035',
}

local prizepoolClasses = {
	'background-color-first-place',
	'background-color-second-place',
	'background-color-third-place',
	'background-color-fourth-place',
	w = 'bg-win',
	q = 'bg-win',
	d = 'bg-draw',
	l = 'bg-lose',
	dq = 'bg-dq',
}

---Processes a placement text input into raw data.
---Returned table will not always contain every key.
---@param placement string?
---@return table
function Placement.raw(placement)
	local raw = {}

	-- Nil check on input and split placement if joint
	raw.placement = mw.text.split(string.lower(placement or ''), '-', true)

	-- Identify appropriate background class
	if raw.placement[1] == '3' and raw.placement[2] then
		raw.backgroundClass = PLACEMENT_CLASSES['d']
	elseif PLACEMENT_CLASSES[raw.placement[1]] then
		raw.backgroundClass = PLACEMENT_CLASSES[raw.placement[1]]
	elseif Logic.isNumeric(raw.placement[1]) and tonumber(raw.placement[1]) <= 128 then
		raw.backgroundClass = PLACEMENT_CLASSES['17']
	elseif Logic.isNumeric(raw.placement[1]) then
		raw.backgroundClass = PLACEMENT_CLASSES['129']
	else
		raw.unknown = true
	end

	-- Intercept non-numeric placements for sorting and ordinal creation
	if not Logic.isNumeric(raw.placement[1]) then
		raw.sort = CUSTOM_SORTS[raw.placement[1]] or CUSTOM_SORTS['']
		raw.ordinal = mw.text.split(string.upper(placement or ''), '-', true)
	else
		raw.sort = raw.placement[1] .. (raw.placement[2] and ('-' .. raw.placement[2]) or '')
		raw.ordinal = Placement._makeOrdinal(raw.placement)
	end

	-- Create placement display from ordinal (or not) variants
	if not raw.unknown then
		raw.display = raw.ordinal[1] .. (raw.ordinal[2] and ('&nbsp;-&nbsp;' .. raw.ordinal[2]) or '')
	else
		mw.log('No placement found in Module:Placement: ' .. placement)
		raw.display = placement .. '[[Category:Pages with unknown placements]]'
	end

	-- Determine any black text placements
	raw.blackText = (raw.placement[1] == 'dnp')

	return raw
end

---Takes a table of placement numbers and makes them ordinal.
---@param placement table
---@return table
function Placement._makeOrdinal(placement)
	return Table.mapValues(placement,
		function(place)
			return Ordinal._ordinal(place)
		end
	)
end


---Takes parent mw html object and childs a placement.
---Expected args fields are `parent` and `placement`.
---@param placement table?
---@return nil
function Placement._placement(args)
	if not (type(args) == 'table' and type(args.parent) == 'table') then
		return
	end
	local raw = Placement.raw(args.placement or '')
	args.parent:css('text-align', 'center')
			   :attr('data-sort-value', raw.sort)
			   :addClass(raw.backgroundClass)
			   :tag('b')
			   :addClass(not raw.blackText and 'placement-text' or nil)
			   :wikitext(raw.display)

end

---Converts a placement table into a ordinal string.
---@param placement table
---@return string
function Placement.RangeLabel(range)
	local ordinal = Placement._makeOrdinal(range)
	return table.concat({
		ordinal[1],
		range[1] < range[2] and ordinal[2] or nil,
	}, ZERO_WIDTH_SPACE .. EN_DASH .. ZERO_WIDTH_SPACE)
end

---Takes string place value and returns prize pool color class.
---May return `nil` if no color is registered.
---@param placement string
---@return string?
function Placement.getBgClass(placement)
	return prizepoolClasses[placement]
end

---Produces wikicode table code for a placement for use in wikitables.
---Can optionally take a `customText` input for custom display text.
---@param placement string
---@param customText string?
---@return string
function Placement.get(placement, customText)
	local raw = Placement.raw(placement)
	return 'class="text-center ' .. (raw.backgroundClass or '') .. '" data-sort-value="' .. raw.sort .. '"' ..
		'|<b' .. (raw.blackText and '' or ' class="placement-text"') .. '>' .. (customText or raw.display) .. '</b>'
end

return Class.export(Placement)
