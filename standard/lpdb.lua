---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lpdb = {}

local Table = require('Module:Table')

function Lpdb.executeMassQuery(lpdbTable, queryParameters, callbackFunction, limit, breakCallbackFunction)
	queryParameters.offset = queryParameters.offset or 0
	queryParameters.limit = queryParameters.limit or 5000
	breakCallbackFunction = breakCallbackFunction or Lpdb._defaultBbreakCallbackFunction

	local lpdbData = {}
	while queryParameters.offset < limit do
		queryParameters.limit = math.min(queryParameters.limit, limit - queryParameters.offset)

		lpdbData = mw.ext.LiquipediaDB.lpdb(lpdbTable, queryParameters)
		Table.iter.forEachIndexed(lpdbData, callbackFunction)

		queryParameters.offset = queryParameters.offset + #lpdbData
		if #lpdbData < queryParameters.limit or breakCallbackFunction() then
			break
		end
	end
end

function Lpdb._defaultBbreakCallbackFunction()
	return false
end

return Lpdb
