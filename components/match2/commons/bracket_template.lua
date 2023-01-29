---
-- @Liquipedia
-- wiki=commons
-- page=Module:Bracket/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})
local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local BracketTemplate = {}

-- Entry point of Template:BracketDocumentation
function BracketTemplate.TemplateBracketDocumentation()
	local argsList = Template.retrieveReturnValues('BracketTemplate')
	local bracket = BracketTemplate.readBracket(argsList)

	BracketTemplate.store(bracket)
	return BracketTemplate.BracketDocumentation({templateId = bracket.templateId})
end

function BracketTemplate.BracketDocumentation(props)
	local parts = {
		[[
==Bracket==
]],
		BracketTemplate.BracketContainer({bracketId = props.templateId}),
		[[

==Template==
Refresh the page to generate a new ID.
]],
		mw.html.create('pre'):addClass('brkts-template-container'),
	}
	return table.concat(Array.map(parts, tostring))
end

function BracketTemplate.BracketContainer(props)
	return BracketDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
		config = Table.merge(props.config, {
			OpponentEntry = function() return mw.html.create('div'):addClass('brkts-opponent-entry') end,
			matchHasDetails = function() return false end,
		})
	})
end

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

function BracketTemplate.readBracketData(args)
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

function BracketTemplate.store(bracket)
	BracketTemplate.storeBracket(bracket)
	BracketTemplate.storeDatapoint(bracket.templateId)
end

--[[
Store bracket with placeholder match and opponent data in commons wiki LPDB
]]
function BracketTemplate.storeBracket(bracket)
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
