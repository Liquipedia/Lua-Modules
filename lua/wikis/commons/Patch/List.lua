---
-- @Liquipedia
-- wiki=commons
-- page=Module:Patch/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Condition = require('Module:Condition')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local PatchList = {}

-- Track the most recent patch across all tables
PatchList.globalLatestPatchDate = nil
PatchList.globalLatestPatchId = nil

-- Predefined column structure (moved outside of function to avoid recreation)
local baseColumns = {
	-- Patch name column with link and optional latest marker
	{
		title = '<span class="fas fa-file-alt"></span> Patch',
		style = 'width: 280px;',
		func = function(patch)
			local name = String.nilIfEmpty(patch.name) or patch.pagename:gsub('_', ' '):gsub('^Patch/', '')
			local link = '[[' .. patch.pagename .. '|' .. name .. ']]'
			if patch.isLatest then
				link = link .. ' (latest)'
			end
			return link
		end
	},
	-- Release date column formatted for readability
	{
		title = '<span class="gray-text fas fa-calendar-alt"></span> Release Date',
		style = 'width: 180px;',
		func = function(patch)
			return patch.date and mw.getContentLanguage():formatDate('F j, Y', patch.date) or nil
		end
	},
	-- Highlights column displaying key patch features
	{
		title = '<span class="gold-text fas fa-star"></span> Release Highlights',
		style = 'width: 490px;',
		func = function(patch)
			local highlights = patch.highlights or {}
			if type(highlights) ~= 'table' then
				highlights = {}
			end
			return table.concat(PatchList._makeList(highlights))
		end
	},
}

-- Version column definition (used conditionally)
local versionColumn = {
	title = 'Version',
	style = 'width: 280px;',
	func = function(patch)
		if patch.version then
			local versionText
			local versions = mw.text.split(patch.version:gsub('%(', '|'):gsub('%)', '|'), '|', true)
			versionText = versions[1] and ('<b>' .. mw.text.trim(versions[1]) .. '</b>') or ''
			if versions[2] then
				versionText = versionText .. ' (' .. versions[2] .. ')'
			end
			return versionText
		end
	end
}

-- Date format validation pattern (compile once)
local datePattern = '^%d%d%d%d%-%d%d%-%d%d$'

--- Fetches patch data from the Liquipedia database based on provided arguments
--- @param args table Parameters controlling the query, such as game, date range, and limit
--- @return table Array of patch data retrieved from the database
function PatchList.getPatches(args)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('type'), Comparator.eq, 'patch')
		}

	if args.game then
		conditions:add{
			ConditionNode(ColumnName('extradata_game'), Comparator.eq, args.game)
		}
	end

	local startDate = args.sdate
	local endDate = args.edate

	-- Basic date validation (expects YYYY-MM-DD format)
	if startDate and not startDate:match(datePattern) then
		error("Invalid start date format: " .. startDate .. ". Use YYYY-MM-DD.")
	end
	if endDate and not endDate:match(datePattern) then
		error("Invalid end date format: " .. endDate .. ". Use YYYY-MM-DD.")
	end

	-- Year-based filtering using date ranges
	if args.year then
		local year = tonumber(args.year)
		if year then
			startDate = string.format("%04d-01-01", year)
			endDate = string.format("%04d-12-31", year)
		end
	end

	-- Date range conditions using Boolean operators
	if startDate then
		conditions:add{
			ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('date'), Comparator.gt, startDate),
				ConditionNode(ColumnName('date'), Comparator.eq, startDate)
			}
		}
	end
	if endDate then
		conditions:add{
			ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('date'), Comparator.lt, endDate),
				ConditionNode(ColumnName('date'), Comparator.eq, endDate)
			}
		}
	end

	return mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions:toString(),
		order = 'date desc, pageid desc',
		limit = math.min(tonumber(args.limit) or 100, 5000)
	})
end

--- Formats an array of highlights into a wiki-compatible list
--- @param arr table Array of highlight strings
--- @return table Array of formatted list items
function PatchList._makeList(arr)
	local result = {}
	for _, value in ipairs(arr) do
		if String.isNotEmpty(value) then
			table.insert(result, '\n* ' .. value .. '\n')
		end
	end
	return result
end

--- Builds the table header based on the columns table
--- @param columns table The list of columns to include in the header
--- @return string The constructed header row HTML
local function buildHeader(columns)
	local header = mw.html.create('tr')
	for _, column in ipairs(columns) do
		header:tag('th')
			:cssText(column.style)
			:css('font-size', '16px')
			:wikitext(column.title)
	end
	return header
end

--- Builds a row for a single patch
--- @param patch table The patch data
--- @param columns table The list of columns to display
--- @return string The constructed row HTML
local function buildRow(patch, columns)
	local row = mw.html.create('tr')
	for _, column in ipairs(columns) do
		row:tag('td')
			:cssText(column.style)
			:css('font-size', '14px')
			:wikitext(column.func(patch))
	end
	return row
end

--- Builds a month header row
--- @param monthAnchor string The anchor for the month
--- @param monthAbbr string The abbreviated month name
--- @param columnCount integer The number of columns in the table
--- @return string The constructed month header row HTML
local function buildMonthHeader(monthAnchor, monthAbbr, columnCount)
	local subheaderRow = mw.html.create('tr')
	subheaderRow:tag('td')
		:attr('colspan', columnCount)
		:addClass('gray-bg')
		:css('text-align', 'center')
		:wikitext(
		'<span id="' .. monthAnchor ..
		'" style="position: relative; top: -250px; visibility: hidden;"></span><b>' .. monthAbbr .. '</b>'
	)
	return subheaderRow
end

--- Finds the latest patch across all tables
function PatchList.findLatestPatch()
	local latestPatches = PatchList.getPatches({limit = 1})
	if #latestPatches > 0 then
		local latestPatch = latestPatches[1]
		PatchList.globalLatestPatchDate = latestPatch.date
		PatchList.globalLatestPatchId = latestPatch.pageid
	end
end

--- Creates and returns the patch table display
--- Entry point for the module
--- @param frame table The MediaWiki frame object providing arguments
--- @return string HTML string representing the patch table
function PatchList.create(frame)
	local args = Arguments.getArgs(frame)

	-- Configure table classes for collapsibility
	local tableClasses = 'wikitable mw-collapsible'
	if Logic.readBool(args.collapsed) then
		tableClasses = tableClasses .. ' mw-collapsed'
	end

	-- Copy columns to avoid modifying the original
	local columns = {}
	for i, col in ipairs(baseColumns) do
		columns[i] = col
	end

	-- Add optional version column if requested
	if Logic.readBool(args.showVersion) then
		table.insert(columns, 2, versionColumn)
	end

	-- Initialize the latest patch tracking if not already done
	if not PatchList.globalLatestPatchDate then
		PatchList.findLatestPatch()
	end

	-- Retrieve patch data from database
	local patches = PatchList.getPatches(args)
	if #patches == 0 then
		local filterInfo = ""
		if args.game then filterInfo = filterInfo .. " game='" .. args.game .. "'" end
		if args.sdate then filterInfo = filterInfo .. " sdate='" .. args.sdate .. "'" end
		if args.edate then filterInfo = filterInfo .. " edate='" .. args.edate .. "'" end
		return "No patches found for the given criteria:" .. (filterInfo ~= "" and filterInfo or " none specified") .. "."
	end

	-- Initialize responsive table container
	local wrapper = mw.html.create('div')
		:addClass('table-responsive')

	-- Build table structure with styling
	local output = wrapper:tag('table')
		:addClass(tableClasses)

	-- Add table header
	output:node(buildHeader(columns))

	local currentMonth = nil
	-- Check if month headers should be displayed
	local showMonthHeaders = not Logic.readBool(args.noheadermonth)
	local previousMonthAnchors = {}

	-- Prepare content formatter (outside the loop)
	local contentLanguage = mw.getContentLanguage()

	-- Populate table with patch data and month headers
	for _, patchData in ipairs(patches) do
		-- Extract extradata once
		local extradata = patchData.extradata or {}
		patchData.extradata = nil

		-- Process extradata more efficiently
		for k, v in pairs(extradata) do
			if type(v) == 'string' and (v:find('{') or v:find('%[')) then
				local parsed = Json.parseIfTable(v)
				if parsed then
					patchData[k] = parsed
				else
					patchData[k] = v
				end
			else
				patchData[k] = v
			end
		end

		-- Check if this patch is the latest overall
		patchData.isLatest = (
			patchData.date == PatchList.globalLatestPatchDate
			and patchData.pageid == PatchList.globalLatestPatchId
		)

		-- Extract month and year for grouping
		local monthAbbr = patchData.date and contentLanguage:formatDate('M', patchData.date) or ''
		local year = patchData.date and contentLanguage:formatDate('Y', patchData.date) or ''
		local monthAnchor = monthAbbr .. '_' .. year

		-- Insert month header or hidden anchor when month changes
		if monthAbbr ~= currentMonth then
			if showMonthHeaders then
				-- Insert visible month header with anchor
				output:node(buildMonthHeader(monthAnchor, monthAbbr, #columns))
			else
				-- Check if we've already added this anchor (to avoid duplicates)
				if not previousMonthAnchors[monthAnchor] then
					-- Insert hidden anchor only (no visible header)
					local anchorRow = mw.html.create('tr')
						:css('height', '0')
						:css('padding', '0')
						:css('margin', '0')
						:css('border', 'none')

					anchorRow:tag('td')
						:attr('colspan', #columns)
						:css('height', '0')
						:css('padding', '0')
						:css('margin', '0')
						:css('border', 'none')
						:wikitext(
						'<span id="' .. monthAnchor .. '" style="position: relative; top: -250px; visibility: hidden;"></span>'
					)

					output:node(anchorRow)
					previousMonthAnchors[monthAnchor] = true
				end
			end
			currentMonth = monthAbbr
		end

		-- Add patch data row
		output:node(buildRow(patchData, columns))
	end

	-- Append footer with back-to-top link
	output:tag('tr')
		:tag('td')
			:attr('colspan', #columns)
			:css('text-align', 'center')
			:wikitext("'''[[#top|Back to the Top]]'''")

	-- Return the completed table as a string
	return tostring(wrapper)
end

return PatchList
