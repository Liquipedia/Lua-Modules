---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lpdb = {}

local _DEFAULT_QUERY_LIMIT = 20
local _DEFAULT_INITIAL_OFFSET = 0

--[==[
Wrapper for mass LPDB queries.
Used when > 5000 results are needed (LPDB max limit is 5000) or when
additional filtering is to be done after the query and memory is an issue.

example:
	local cond = '[[match2id::!]]'
	local query = 'match2id'

	local function queryFunct(foundElements, offset, maxQueryLimit)
		local data = mw.ext.LiquipediaDB.lpdb('match2', {
			limit = maxQueryLimit,
			offset = offset,
			conditions = cond,
			query = query,
		})

		for _, item in ipairs(data) do
			if string.match(item.match2id, '_0001') then
				table.insert(foundElements, item.match2id)
			end
		end

		return foundElements, #data
	end

	local queryData = Lpdb.massQueryWrapper(queryFunct, 0, 5000)
]==]
function Lpdb.massQueryWrapper(funct, initialOffset, maxQueryLimit, maxRounds)
	local offset = initialOffset or _DEFAULT_INITIAL_OFFSET
	local count = maxQueryLimit or _DEFAULT_QUERY_LIMIT
	maxRounds = maxRounds or math.huge
	local rounds = 0

	local foundElements = {}

	while count == maxQueryLimit and rounds < maxRounds do
		foundElements, count = funct(foundElements, offset, maxQueryLimit)

		offset = offset + maxQueryLimit
		rounds = rounds + 1
	end

	return foundElements
end

return Lpdb
