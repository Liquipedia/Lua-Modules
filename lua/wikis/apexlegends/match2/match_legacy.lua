---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')


function MatchLegacy.storeMatch(match2)
	MatchLegacy._storeMatch1(match2)
end

function MatchLegacy._storeMatch1(match2)
	for gameIndex, game2 in ipairs(match2.match2games or {}) do
		local match = Table.deepCopy(match2)
		local g2extradata = Json.parseIfString(game2.extradata) or {}

		match.date = game2.date
		match.vod = game2.vod
		match.dateexact = g2extradata.dateexact
		match.finished = String.isNotEmpty(game2.winner)
		match.staticid = match2.match2id .. '_' .. gameIndex

		-- Handle extradata fields
		local bracketData = Json.parseIfString(match2.match2bracketdata)
		if type(bracketData) == 'table' and bracketData.inheritedheader then
			match.header = (DisplayHelper.expandHeader(bracketData.inheritedheader) or {})[1]
		end
		local m1extradata = {}

		m1extradata.map = game2.map
		m1extradata.round = tostring(gameIndex)

		match.extradata = mw.ext.LiquipediaDB.lpdb_create_json(m1extradata)

		mw.ext.LiquipediaDB.lpdb_match('legacymatch_' .. match2.match2id .. '_' .. gameIndex, match)
	end
end

return MatchLegacy
