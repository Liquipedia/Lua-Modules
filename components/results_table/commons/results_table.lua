---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local DEFAULT_VALUES = {
	order = 'desc',
	playerPrefix = 'p',
	coachPrefix = 'c',
	resolveOpponent = true,
	playerLimit = 10,
	coachLimit = 5,
	achievementsLimit = 10,
	resultsLimit = 5000,
}
local COACH_TYPE = 'coach'
local VALID_QUERY_TYPES = {
	COACH_TYPE,
	Opponent.solo,
	Opponent.team,
}

--- @class ResultsTable
local ResultsTable = Class.new(function(self, ...) self:init(...) end)

function ResultsTable:init(args)
	self.args = args

	self.pagename = mw.title.getCurrentTitle().text

	self.config = self:readConfig()

	return self
end

function ResultsTable:readConfig()
	local args = self.args

	local config = {
		order = args.order or DEFAULT_VALUES.order,
		playerPrefix = args.prefixplayer or DEFAULT_VALUES.playerPrefix,
		coachPrefix = args.prefixcoach or DEFAULT_VALUES.coachPrefix,
		hideResult = Logic.readBool(args.hideresult),
		resolveOpponent = Logic.readBool(args.resolve or DEFAULT_VALUES.resolveOpponent),
		gameIconsData = args.gameIcons,
		opponent = mw.text.decode(args.coach or args.player or args.team or self:_getOpponent()),
		queryType = self:getQueryType(),
		onlyAchievements = Logic.readBool(args.achievements),
	}

	config.sort = args.sort or
		(config.onlyAchievements and 'weight' or 'date')

	config.limit = tonumber(args.limit) or
		(config.onlyAchievements and DEFAULT_VALUES.achievementsLimit or DEFAULT_VALUES.resultsLimit)

	config.playerLimit =
		(config.queryType == Opponent.solo and tonumber(args.playerLimit) or DEFAULT_VALUES.playerLimit)
		or (config.queryType == COACH_TYPE and tonumber(args.coachLimit) or DEFAULT_VALUES.coachLimit)

	return config
end

function ResultsTable:_getOpponent()
	if Namespace.isMain() then
		return mw.title.getCurrentTitle().baseText
	elseif String.contains(mw.title.getCurrentTitle().subpageText:lower(), 'results') then
		local pageName = mw.text.split(mw.title.getCurrentTitle().text, '/')
		return pageName[#pageName - 1]
	end

	return mw.title.getCurrentTitle().subpageText
end

function ResultsTable:getQueryType()
	local args = self.args

	if args.querytype then
		local queryType = args.querytype:lower()
		if Table.includes(VALID_QUERY_TYPES, queryType) then
			return queryType
		end

		error('Invalid querytype "' .. args.querytype .. '"')
	end

	if args.coach then
		return COACH_TYPE
	elseif args.player then
		return Opponent.solo
	end

	return Opponent.team
end

-- todo:
-- > query data
-- > build display from config and data
-- > option for querying results for players on a certain team (adjust config)

return ResultsTable
