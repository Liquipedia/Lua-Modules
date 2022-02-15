---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lpdb = {}

function Lpdb.executeMassQuery(lpdbTable, queryParameters, callbackFunction, limit)
	queryParameters.offset = queryParameters.offset or 0
	queryParameters.limit = queryParameters.limit or 5000
	limit = limit or math.huge

	while queryParameters.offset < limit do
		queryParameters.limit = math.min(queryParameters.limit, limit - queryParameters.offset)

		local lpdbData = mw.ext.LiquipediaDB.lpdb(lpdbTable, queryParameters)
		for _, value in ipairs(lpdbData) do
			local success = callbackFunction(value)
			if success == false then
				return
			end
		end

		queryParameters.offset = queryParameters.offset + #lpdbData
		if #lpdbData < queryParameters.limit then
			return
		end
	end
end

return Lpdb
