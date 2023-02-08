---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Workaround
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local Table = require('Module:Table')

local MatchGroupWorkaround = {}

--[[
Applies a workaround to a match record for the bug where player records are
sometimes attached to the wrong opponent record. See https://github.com/Liquipedia/Lua-Modules/pull/528
for a more detailed description.
]]
function MatchGroupWorkaround.applyPlayerBugWorkaround(matchRecord)
	if not FeatureFlag.get('issue528_workaround') then
		return
	end

	local playerRecords = Table.getByPathOrNil(matchRecord, {'match2opponents', 1, 'match2players'})
	if not playerRecords then return end

	-- The bug is present if any of the player records attached to the first opponent are from other opponents
	local bugIsPresent = Array.any(playerRecords, function(playerRecord) return playerRecord.opid ~= 1 end)
	if not bugIsPresent then return end

	mw.log('MatchGroupWorkaround.applyPlayerBugWorkaround: Applying workaround for matchid=' .. matchRecord.match2id)

	local allPlayerRecords = Array.flatten(Array.map(matchRecord.match2opponents, function(opponentRecord)
		return opponentRecord.match2players or {}
	end))
	local _, byOpponentIx = Array.groupBy(allPlayerRecords, function(playerRecord) return playerRecord.opid end)
	for opponentIx, opponentRecord in ipairs(matchRecord.match2opponents) do
		opponentRecord.match2players = byOpponentIx[opponentIx] or {}
		Array.sortInPlaceBy(opponentRecord.match2players, function(playerRecord) return playerRecord.id end)
	end
end

return MatchGroupWorkaround
