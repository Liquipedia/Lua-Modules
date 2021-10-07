---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local StringUtils = require('Module:StringUtils')
local Table = require('Module:Table')

local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})
local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local pageVars = PageVariableNamespace('MatchGroupTemplate')

local MatchGroupTemplate = {}

-- Entry point from Template:TemplateMatch
function MatchGroupTemplate.TemplateTemplateMatch(frame)
	local args = Arguments.getArgs(frame)
	local count = tonumber(pageVars:get('count')) or 0
	pageVars:set('count', count + 1)
	pageVars:set(count + 1, Json.stringify(args))
end

-- Entry point from Template:BracketDocumentation
function MatchGroupTemplate.TemplateBracketDocumentation()
	-- Retrieve bracket args from page variables
	local argsList = {}
	for ix = 1, tonumber(pageVars:get('count')) or 0 do
		table.insert(argsList, Json.parseIfString(pageVars:get(ix)))
	end

	-- Read bracket datas from input spec
	local bracket = MatchGroupTemplate.read(argsList)

	-- Compute coordinates and attach to bracket datas
	local bracketCoordinates = MatchGroupCoordinates.computeCoordinates(bracket)
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		bracketData.coordinates = bracketCoordinates.coordinatesByMatchId[matchId]
	end

	-- Store blank bracket with bracket datas in LPDB
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
