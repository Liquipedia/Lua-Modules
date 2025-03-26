---
-- @Liquipedia
-- wiki=commons
-- page=Module:Patch/Calendar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local PatchList = require('Module:PatchList')

local PatchCalendar = {}

function PatchCalendar.create(frame)
	local args = Arguments.getArgs(frame)
	local year = tonumber(args.year) or tonumber(mw.getContentLanguage():formatDate('Y'))
	local sdate = args.sdate
	local edate = args.edate

	-- Create parameters table to pass to PatchList.getPatches
	local params = {}

	-- If sdate/edate are provided, use them for filtering
	if sdate then
		params.sdate = sdate
		-- Extract year from sdate if available (for header)
		if sdate:match('^%d%d%d%d%-%d%d%-%d%d$') then
			year = tonumber(sdate:sub(1, 4)) or year
		end
	else
		-- Use year parameter if sdate isn't provided
		params.year = tostring(year)
	end

	-- Add edate parameter if it exists
	if edate then
		params.edate = edate
	end

	-- Add game parameter if it exists
	if args.game then
		params.game = args.game
	end

	-- Fetch patches for the specified criteria
	local patches = PatchList.getPatches(params)

	-- Filter patches based on year displayed
	local filteredPatches = {}
	for _, patch in ipairs(patches) do
		if patch.date then
			local patchYear = tonumber(mw.getContentLanguage():formatDate('Y', patch.date))
			if patchYear == year then
				table.insert(filteredPatches, patch)
			end
		end
	end

	-- Track which months have patches (using filtered patches)
	local monthsPresent = {}
	for _, patch in ipairs(filteredPatches) do
		if patch.date then
			local month = tonumber(mw.getContentLanguage():formatDate('n', patch.date))
			if month then
				monthsPresent[month] = true
			end
		end
	end

	-- Create a responsive wrapper for the table
	local wrapper = mw.html.create('div')
		:addClass('table-responsive')

	-- Build the calendar table
	local tbl = wrapper:tag('table')
		:addClass('wikitable')
		:attr('style', 'text-align:center; font-size:110%;')

	-- Year header row
	tbl:tag('tr')
		:addClass('gray-bg')
		:tag('td')
		:attr('colspan', 6)
		:wikitext("'''" .. year .. "'''")

	-- First row (January - June)
	local tr1 = tbl:tag('tr')
	for monthNum = 1, 6 do
		local monthAbbr = mw.getContentLanguage():formatDate('M', string.format('%04d-%02d-01', year, monthNum))
		local anchor = monthAbbr .. '_' .. year
		local cellContent = monthsPresent[monthNum]
			and '[[#' .. anchor .. '|' .. monthAbbr .. ']]'
			or '<s>' .. monthAbbr .. '</s>'
		tr1:tag('td'):wikitext(cellContent)
	end

	-- Second row (July - December)
	local tr2 = tbl:tag('tr')
	for monthNum = 7, 12 do
		local monthAbbr = mw.getContentLanguage():formatDate('M', string.format('%04d-%02d-01', year, monthNum))
		local anchor = monthAbbr .. '_' .. year
		local cellContent = monthsPresent[monthNum]
			and '[[#' .. anchor .. '|' .. monthAbbr .. ']]'
			or '<s>' .. monthAbbr .. '</s>'
		tr2:tag('td'):wikitext(cellContent)
	end

	return tostring(wrapper)
end

return PatchCalendar
