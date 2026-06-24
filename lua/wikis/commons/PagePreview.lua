---
-- @Liquipedia
-- page=Module:PagePreview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local String = Lua.import('Module:StringUtils')

local PagePreview = {}

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
		name = String.nilIfEmpty(row.id) or row.name,
		realName = String.nilIfEmpty(row.name),
		flag = String.nilIfEmpty(row.nationality),
		team = String.nilIfEmpty(row.team),
		role = String.nilIfEmpty(extradata.role),
		status = String.nilIfEmpty(row.status),
		earnings = earnings and tonumber(earnings) or nil,
		image = String.nilIfEmpty(row.imageurl),
	}
end

return PagePreview
