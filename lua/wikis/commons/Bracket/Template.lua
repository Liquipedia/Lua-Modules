---
-- @Liquipedia
-- page=Module:Bracket/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
local Match = Lua.import('Module:Match')
local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Opponent = Lua.import('Module:Opponent')

---@class BracketTemplateBracket
---@field bracketDatasById table<string,MatchGroupUtilBracketBracketData>
---@field rootMatchIds string[]
---@field templateId string

local BracketTemplate = {}

-- Entry point of Template:BracketDocumentation
---@return string
function BracketTemplate.TemplateBracketDocumentation()
	local argsList = Template.retrieveReturnValues('BracketTemplate')
	local bracket = BracketTemplate.readBracket(argsList)

	BracketTemplate.store(bracket)
	return BracketTemplate.BracketDocumentation({templateId = bracket.templateId})
end

---@param props {templateId: string}
---@return string
function BracketTemplate.BracketDocumentation(props)
	local parts = {
		[[
==Bracket==
]],
		BracketTemplate.BracketContainer({bracketId = props.templateId}),
		[[

==Copy-Paste==
For copy-pastable code please use <code>Special:RunQuery/BracketCopyPaste</code> on the respective wiki(s).
]],
	}
	return table.concat(Array.map(parts, tostring))
end

---@param props {bracketId: string, config: table?}
---@return Html
function BracketTemplate.BracketContainer(props)
	local matchRecords = MatchGroupUtil.fetchMatchRecords(props.bracketId)
	Array.forEach(matchRecords, function(match)
		match.match2opponents = {{type = Opponent.literal, name = '', match2players = {}}}
	end)
	local bracket = MatchGroupUtil.makeMatchGroup(matchRecords) --[[@as MatchGroupUtilBracket]]

	return BracketDisplay.Bracket({
		bracket = bracket,
		config = Table.merge(props.config, {
			OpponentEntry = function() return mw.html.create('div'):addClass('brkts-opponent-entry') end,
			matchHasDetails = function() return false end,
		})
	})
end

---@param argsList table[]
---@return BracketTemplateBracket
function BracketTemplate.readBracket(argsList)
	local bracketDataList = Array.map(argsList, BracketTemplate.readBracketData)

	local bracket = {
		bracketDatasById = Table.map(
			bracketDataList,
			function(_, bracketData) return bracketData.matchId, bracketData end
		),
		rootMatchIds = {},
		templateId = mw.title.getCurrentTitle().text,
	}

	-- Populate in bracketData.upperMatchId and rootMatchIds
	local upperMatchIds = MatchGroupCoordinates.computeUpperMatchIds(bracket.bracketDatasById)
	for _, bracketData in ipairs(bracketDataList) do
		local upperMatchId = upperMatchIds[bracketData.matchId]
		if not upperMatchId
			and not String.endsWith(bracketData.matchId, 'RxMBR') then
			table.insert(bracket.rootMatchIds, bracketData.matchId)
		end
		bracketData.upperMatchId = upperMatchId
	end

	-- Populate bracketData.coordinates
	local bracketCoordinates = MatchGroupCoordinates.computeCoordinates(bracket)
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		bracketData.coordinates = bracketCoordinates.coordinatesByMatchId[matchId]
	end

	return bracket
end

---@param args table
---@return MatchGroupUtilBracketBracketData
function BracketTemplate.readBracketData(args)
	local pageName = mw.title.getCurrentTitle().text
	local function joinPageName(baseMatchId)
		return pageName .. '_' .. baseMatchId
	end

	args.type = 'bracket'
	local bracketData = MatchGroupUtil.bracketDataFromRecord(args)
	--bracketData is of type bracket
	---@cast bracketData - MatchGroupUtilMatchlistBracketData
	bracketData.bracketResetMatchId = bracketData.bracketResetMatchId and joinPageName(bracketData.bracketResetMatchId)
	bracketData.lowerMatchIds = Array.map(bracketData.lowerMatchIds, joinPageName)
	bracketData.matchId = joinPageName(args.matchid)
	bracketData.thirdPlaceMatchId = bracketData.thirdPlaceMatchId and joinPageName(bracketData.thirdPlaceMatchId)
	bracketData.upperMatchId = bracketData.upperMatchId and joinPageName(bracketData.upperMatchId)
	return bracketData
end

---@param bracket BracketTemplateBracket
function BracketTemplate.store(bracket)
	BracketTemplate.storeBracket(bracket)
	BracketTemplate.storeDatapoint(bracket.templateId)
end

---Store bracket with placeholder match and opponent data in commons wiki LPDB
---@param bracket BracketTemplateBracket
function BracketTemplate.storeBracket(bracket)
	for matchId, bracketData in pairs(bracket.bracketDatasById) do
		local bracketId, baseMatchId = MatchGroupUtil.splitMatchId(matchId)
		assert(baseMatchId, 'Invalid matchId "' .. matchId .. '"')
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

---@param templateId string
function BracketTemplate.storeDatapoint(templateId)
	mw.ext.LiquipediaDB.lpdb_datapoint('ExtensionBracket_' .. templateId, {
		type = 'extension bracket',
	})
end

BracketTemplate.perfConfig = {
	locations = {
		'Module:Bracket/Template|*',
		'Module:MatchGroup/Coordinates|*',
		'Module:MatchGroup/Display/Bracket|*',
	}
}

return BracketTemplate
