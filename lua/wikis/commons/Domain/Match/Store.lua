---
-- @Liquipedia
-- page=Module:Domain/Match/Store
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Operator = Lua.import('Module:Operator')
local Variables = Lua.import('Module:Variables')

--[[
Where match records come from. Every read of the match2 table belongs here, so that features can
ask the match domain for matches instead of writing their own queries.

Returns raw records; turning them into matches is Module:Domain/Match/Model.
]]
local MatchStore = {}

---Fetches all match ids of matches that satisfy the supplied condition
---@param props {conditions: string|AbstractConditionNode, limit: string|integer?, order: string?}
---@return string[]
function MatchStore.fetchMatchIds(props)
	---@type string[]
	return Array.map(mw.ext.LiquipediaDB.lpdb('match2', {
		limit = tonumber(props.limit) or 1000,
		query = 'match2id',
		conditions = tostring(props.conditions),
		order = props.order
	}), Operator.property('match2id'))
end

---Fetches all matches in a matchlist or bracket. Tries to read from page variables before fetching from LPDB.
---Returns a list of records ordered lexicographically by matchId.
---@param bracketId string
---@return table[]
function MatchStore.fetchMatchRecords(bracketId)
	local varData = Variables.varDefault('match2bracket_' .. bracketId)
	if varData then
		return (Json.parse(varData))
	end

	return mw.ext.LiquipediaDB.lpdb(
		'match2',
		{
			conditions = '([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::' .. bracketId .. ']]',
			order = 'match2id ASC',
			limit = 5000,
		}
	)
end

return MatchStore
