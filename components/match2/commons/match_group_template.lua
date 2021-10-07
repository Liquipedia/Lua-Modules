---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local StringUtils = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})
local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local MatchGroupTemplate = {}

-- Entry point from Template:BracketDocumentation
function MatchGroupTemplate.readAndStoreTemplate()
	local argsList = Template.retrieveReturnValues('MatchGroupTemplate')

	-- Read bracket datas from input spec
	local bracket = MatchGroupTemplate.read(argsList)

	-- Compute coordinates and attach to bracket datas
	local bracketCoordinates = MatchGroupCoordinates.computeCoordinates(bracket)
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		bracketData.coordinates = bracketCoordinates.coordinatesByMatchId[matchId]
	end

	-- Store bracket with placeholder match and opponent data in LPDB
	MatchGroupTemplate.store(bracket)
end

function MatchGroupTemplate.read(argsList)
	local bracketDatas = Array.map(argsList, MatchGroupTemplate.readBracketData)

	local bracket = {
		bracketDatasById = Table.map(
			bracketDatas,
			function(_, bracketData) return bracketData.matchId, bracketData end
		),
		rootMatchIds = {},
	}

	local upperMatchIds = MatchGroupCoordinates.computeUpperMatchIds(bracket.bracketDatasById)
	for _, bracketData in ipairs(bracketDatas) do
		local upperMatchId = upperMatchIds[bracketData.matchId]
		if not upperMatchId
			and not StringUtils.endsWith(bracketData.matchId, 'RxMBR') then
			table.insert(bracket.rootMatchIds, bracketData.matchId)
		end
		bracketData.upperMatchId = upperMatchId
	end

	return bracket
end

function MatchGroupTemplate.store(bracket)
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		local bracketId, baseMatchId = MatchGroupUtil.splitMatchId(matchId)
		bracketData.matchId = nil

		local opponent = {
			name = MatchGroupUtil.matchIdToKey(baseMatchId),
			type = 'literal',
		}
		local match = {
			bracketid = bracketId,
			match2bracketdata = MatchGroupUtil.bracketDataToRecord(bracketData),
			matchid = baseMatchId,
			opponent1 = opponent,
		}
		Match.store(match)
	end
end

function MatchGroupTemplate.readBracketData(args)
	local pageName = mw.title.getCurrentTitle().text
	local function joinPageName(baseMatchId)
		return pageName .. '_' .. baseMatchId
	end

	args.type = 'bracket'
	local bracketData = MatchGroupUtil.bracketDataFromRecord(args)
	bracketData.bracketResetMatchId = bracketData.bracketResetMatchId and joinPageName(bracketData.bracketResetMatchId)
	bracketData.lowerMatchIds = Array.map(bracketData.lowerMatchIds, joinPageName)
	bracketData.matchId = joinPageName(args.matchid)
	bracketData.thirdPlaceMatchId = bracketData.thirdPlaceMatchId and joinPageName(bracketData.thirdPlaceMatchId)
	bracketData.upperMatchId = bracketData.upperMatchId and joinPageName(bracketData.upperMatchId)
	return bracketData
end

return MatchGroupTemplate
