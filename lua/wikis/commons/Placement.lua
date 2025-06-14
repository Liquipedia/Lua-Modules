---
-- @Liquipedia
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
	['l'] = 'placement-lose',
	['dq'] = 'placement-lose',
	['dnf'] = 'placement-dnp',
	['dns'] = 'placement-dnp',
	['dnpq'] = 'placement-dnp',
	['dnp'] = 'placement-dnp',
	['dnq'] = 'placement-dnp',
	['nc'] = 'placement-dnp',
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
	['dnpq'] = '1033',
	['dnf'] = '1034',
	['dns'] = '1035',
	['dnq'] = '1036',
	['nc'] = '1037',
	['dq'] = '1038',
	['div'] = '1039',
	[''] = '1040',
}

local prizepoolClasses = {
	'background-color-first-place',
	'background-color-second-place',
	'background-color-third-place',
	'background-color-fourth-place',
	w = 'bg-win',
	q = 'bg-win',
	l = 'bg-lose',
	dq = 'bg-dq',
	dnq = 'bg-dq',
	dns = 'bg-dq',
	dnf = 'bg-dq',
	dnp = 'bg-dq',
	dnpq = 'bg-dq',
	nc = 'bg-dq',
}

local USE_BLACK_TEXT = {
	'dnf',
	'dns',
	'dnpq',
	'dnp',
	'dnq',
	'dq',
	'nc',
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
	if PLACEMENT_CLASSES[raw.placement[1]] then
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
	raw.blackText = Table.includes(USE_BLACK_TEXT, raw.placement[1])

	return raw
end

---Takes a table of placement numbers and makes them ordinal.
---@param placement number[]
---@return table
function Placement._makeOrdinal(placement)
	return Table.mapValues(placement,
		function(place)
			return Ordinal.toOrdinal(place)
		end
	)
end


---Takes parent mw html object and childs a placement.
---Expected args fields are `parent` and `placement`.
---@param args table?
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
				:wikitext(raw.display .. (Logic.isNotEmpty(args.text) and (' ' .. args.text) or ''))
end

---Converts a placement table into a ordinal string.
---@param range number[]
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
---@param args {placement: string|number}
---@return string?
function Placement.getBgClass(args)
	return prizepoolClasses[args.placement]
end

---Produces wikicode table code for a placement for use in wikitables.
---Can optionally take a `customText` input for custom display text.
---@param args {placement: string, customText: string?}
---@return string
function Placement.get(args)
	local raw = Placement.raw(args.placement)
	return 'class="text-center ' .. (raw.backgroundClass or '') .. '" data-sort-value="' .. raw.sort .. '"' ..
		'|<b' .. (raw.blackText and '' or ' class="placement-text"') .. '>' .. (args.customText or raw.display) .. '</b>'
end

return Class.export(Placement, {exports = {'getBgClass', 'get', 'RangeLabel'}})
