---
-- @Liquipedia
-- page=Module:PagePreview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local Array = Lua.import('Module:Array')
local Info = Lua.import('Module:Info')
local PlayerTeamRoles = Lua.import('Module:PlayerTeamRoles')
local String = Lua.import('Module:StringUtils')

---@class PagePreviewFieldSpec
---@field label string the row label shown on the card
---@field column string? a top-level LPDB column to fetch and display
---@field extradata (string|string[])? key(s) within the extradata blob to display
---@field separator string? joiner for multiple extradata keys (default ', ')

local PagePreview = {}

local MAX_ENTITIES = 100
-- Collected page names accumulate in a wiki Variable, not module-level state:
-- Scribunto does not persist module state across separate #invoke calls, but
-- wiki Variables do persist across a single page parse. '|' is forbidden in
-- page titles, so it is a safe delimiter.
local COLLECT_VAR = 'pagepreview_pages'

-- Generic LPDB columns fetched for every player card, on every wiki.
local GENERIC_COLUMNS = {
	'pagename', 'id', 'name', 'nationality', 'teampagename', 'status',
	'earnings', 'imageurl', 'birthdate', 'deathdate', 'extradata',
}

---@param name any
---@return boolean
local function isValidColumn(name)
	-- column names come from wiki Info.lua and are spliced into the LPDB query,
	-- so restrict them to bare identifiers to keep the query uninjectable
	return type(name) == 'string' and name:match('^[%w_]+$') ~= nil
end

---clears the collected page names (test-only)
function PagePreview.reset()
	mw.ext.VariablesLua.vardefine(COLLECT_VAR, '')
end

---records a page name to be resolved at flush time
---@param pageName string?
function PagePreview.register(pageName)
	if not pageName or pageName == '' then
		return
	end
	local current = mw.ext.VariablesLua.var(COLLECT_VAR)
	if current == nil or current == '' then
		mw.ext.VariablesLua.vardefine(COLLECT_VAR, PagePreview.key(pageName))
		return
	end
	-- cheap accumulator cap: count delimiters to bound the Variable's growth
	local _, count = current:gsub('|', '')
	if count + 1 >= MAX_ENTITIES then
		return
	end
	mw.ext.VariablesLua.vardefine(COLLECT_VAR, current .. '|' .. PagePreview.key(pageName))
end

---normalizes a page name to its LPDB pagename form (spaces -> underscores)
---@param pageName string
---@return string
function PagePreview.key(pageName)
	return (pageName:gsub(' ', '_'))
end

---the wiki-specific extra preview field specs, from Info.config.pagePreview.player
---@return PagePreviewFieldSpec[]
function PagePreview.extraSpecs()
	local config = Info.config.pagePreview or {}
	return config.player or {}
end

---the extra wiki-specific LPDB columns to add to the query (validated, deduped
---against the generic columns)
---@param specs PagePreviewFieldSpec[]
---@return string[]
function PagePreview.extraColumns(specs)
	local generic = {}
	Array.forEach(GENERIC_COLUMNS, function(column) generic[column] = true end)
	local columns, seen = {}, {}
	Array.forEach(specs, function(spec)
		local column = spec.column
		if isValidColumn(column) and not generic[column] and not seen[column] then
			seen[column] = true
			table.insert(columns, column)
		end
	end)
	return columns
end

---resolves the wiki-specific extra fields for a row into {label, value} rows,
---or nil when none resolve. `column` reads a top-level LPDB column; `extradata`
---reads one or more keys from the (already fetched) extradata blob, joined.
---@param row table
---@param specs PagePreviewFieldSpec[]
---@return {label: string, value: string}[]?
function PagePreview._extra(row, specs)
	local extradata = row.extradata or {}
	local extra = {}
	Array.forEach(specs, function(spec)
		local label = String.nilIfEmpty(spec.label)
		if not label then
			return
		end
		local value
		if isValidColumn(spec.column) then
			local raw = row[spec.column]
			value = raw ~= nil and String.nilIfEmpty(tostring(raw)) or nil
		elseif spec.extradata then
			local keys = type(spec.extradata) == 'table' and spec.extradata or {spec.extradata}
			local parts = {}
			Array.forEach(keys, function(key)
				local part = String.nilIfEmpty(extradata[key])
				if part then
					table.insert(parts, part)
				end
			end)
			value = #parts > 0 and table.concat(parts, spec.separator or ', ') or nil
		end
		if value then
			table.insert(extra, {label = label, value = value})
		end
	end)
	return #extra > 0 and extra or nil
end

---transforms a raw LPDB player row into a compact preview card table
---@param row table
---@param specs PagePreviewFieldSpec[]? wiki-specific extra field specs (defaults to Info config)
---@return table
function PagePreview.parseCard(row, specs)
	local extradata = row.extradata or {}
	local earnings = String.nilIfEmpty(row.earnings)
	return {
		page = PagePreview.key(row.pagename),
		type = 'player',
		name = String.nilIfEmpty(row.id) or String.nilIfEmpty(row.name),
		realName = String.nilIfEmpty(row.name),
		flag = String.nilIfEmpty(row.nationality),
		born = PagePreview._born(row),
		team = PagePreview._team(row),
		role = PagePreview._role(extradata),
		status = String.nilIfEmpty(row.status),
		earnings = earnings and tonumber(earnings) or nil,
		image = (function()
			local imageurl = String.nilIfEmpty(row.imageurl)
			return imageurl and mw.text.decode(imageurl) or nil
		end)(),
		extra = PagePreview._extra(row, specs or PagePreview.extraSpecs()),
	}
end

---builds the infobox-style "Born" string (date + age), or nil. The card JS
---escapes every field, so the &nbsp; AgeCalculation emits is normalized to a
---plain space here to avoid it rendering literally.
---@param row table
---@return string?
function PagePreview._born(row)
	local birthdate = String.nilIfEmpty(row.birthdate)
	if not birthdate then
		return nil
	end
	local ok, age = pcall(AgeCalculation.run, {birthdate = birthdate, deathdate = row.deathdate})
	if not ok or type(age) ~= 'table' then
		return nil
	end
	local born = String.nilIfEmpty(age.birth)
	return born and (born:gsub('&nbsp;', ' ')) or nil
end

---resolves the player's current team from the (non-deprecated) teampagename,
---prettified to display form
---@param row table
---@return string?
function PagePreview._team(row)
	local team = String.nilIfEmpty(row.teampagename)
	return team and (team:gsub('_', ' ')) or nil
end

---maps an extradata role code to its display name via PlayerTeamRoles,
---falling back to the raw code when unmapped (keeps it generic across wikis)
---@param extradata table
---@return string?
function PagePreview._role(extradata)
	local role = String.nilIfEmpty(extradata.role)
	if not role then
		return nil
	end
	local mapped = PlayerTeamRoles[role:lower()]
	return mapped and mapped.display or role
end

---reads the collected page names (deduped, capped) from the wiki Variable
---@return string[]
function PagePreview.collectedKeys()
	local raw = mw.ext.VariablesLua.var(COLLECT_VAR)
	if not raw or raw == '' then
		return {}
	end

	local seen, keys = {}, {}
	for _, key in ipairs(mw.text.split(raw, '|', true)) do
		if key ~= '' and not seen[key] then
			seen[key] = true
			table.insert(keys, key)
			if #keys >= MAX_ENTITIES then
				break
			end
		end
	end
	return keys
end

---queries all collected keys in one batched LPDB request; returns a map of cards
---@return table<string, table>
function PagePreview.collectCards()
	local keys = PagePreview.collectedKeys()
	if #keys == 0 then
		return {}
	end

	local conditions = table.concat(Array.map(keys, function(key)
		return '[[pagename::' .. key .. ']]'
	end), ' OR ')

	local specs = PagePreview.extraSpecs()
	local columns = Array.extend(GENERIC_COLUMNS, PagePreview.extraColumns(specs))

	local ok, rows = pcall(function()
		return mw.ext.LiquipediaDB.lpdb('player', {
			conditions = conditions,
			query = table.concat(columns, ', '),
			limit = MAX_ENTITIES,
		})
	end)
	if not ok or type(rows) ~= 'table' then
		return {}
	end

	local cards = {}
	for _, row in ipairs(rows) do
		local card = PagePreview.parseCard(row, specs)
		cards[card.page] = card
	end
	return cards
end

---emits the preview data island: a hidden div carrying the JSON in a data
---attribute. A <script> tag would be stripped by MediaWiki's HTML sanitizer;
---data-* attributes on a div survive (same mechanism as the repo's other
---data-* output), and mw.html escapes the attribute value for us.
---@param frame Frame?
---@return string
function PagePreview.flush(frame)
	local cards = PagePreview.collectCards()
	if next(cards) == nil then
		return ''
	end
	return tostring(mw.html.create('div')
		:attr('id', 'page-preview-data')
		:css('display', 'none')
		:attr('data-preview', mw.text.jsonEncode(cards)))
end

return PagePreview
