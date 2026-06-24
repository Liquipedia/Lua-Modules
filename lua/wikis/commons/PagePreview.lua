---
-- @Liquipedia
-- page=Module:PagePreview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local String = Lua.import('Module:StringUtils')

local PagePreview = {}

local MAX_ENTITIES = 100
-- Collected page names accumulate in a wiki Variable, not module-level state:
-- Scribunto does not persist module state across separate #invoke calls, but
-- wiki Variables do persist across a single page parse. '|' is forbidden in
-- page titles, so it is a safe delimiter.
local COLLECT_VAR = 'pagepreview_pages'

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

---transforms a raw LPDB player row into a compact preview card table
---@param row table
---@return table
function PagePreview.parseCard(row)
	local extradata = row.extradata or {}
	local earnings = String.nilIfEmpty(row.earnings)
	return {
		page = PagePreview.key(row.pagename),
		type = 'player',
		name = String.nilIfEmpty(row.id) or String.nilIfEmpty(row.name),
		realName = String.nilIfEmpty(row.name),
		flag = String.nilIfEmpty(row.nationality),
		team = String.nilIfEmpty(row.team),
		role = String.nilIfEmpty(extradata.role),
		status = String.nilIfEmpty(row.status),
		earnings = earnings and tonumber(earnings) or nil,
		image = (function()
			local imageurl = String.nilIfEmpty(row.imageurl)
			return imageurl and mw.text.decode(imageurl) or nil
		end)(),
	}
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

	local ok, rows = pcall(function()
		return mw.ext.LiquipediaDB.lpdb('player', {
			conditions = conditions,
			query = 'pagename, id, name, nationality, team, status, earnings, image, imageurl, extradata',
			limit = MAX_ENTITIES,
		})
	end)
	if not ok or type(rows) ~= 'table' then
		return {}
	end

	local cards = {}
	for _, row in ipairs(rows) do
		local card = PagePreview.parseCard(row)
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
