---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

---Note: This can be overwritten
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
---Note: This can be overwritten
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local DEFAULT_VALUES = {
	order = 'desc',
	playerPrefix = 'p',
	coachPrefix = 'c',
	resolveOpponent = true,
	playerLimit = 10,
	coachLimit = 5,
}
local COACH_TYPE = 'coach'
local TYPE_ALIASES = {
	coach = COACH_TYPE,
	['1v1'] = Opponent.solo,
	player = Opponent.solo,
	individual = Opponent.solo,
	solo = Opponent.solo,
	team = Opponent.team,
}

--- @class ResultsTable
local ResultsTable = Class.new(function(self, ...) self:init(...) end)

function ResultsTable:init(args)
	self.args = args

	self.pagename = mw.title.getCurrentTitle().text

	if args.opponentLibrary then
		Opponent = Lua.import('Module:'.. self.args.opponentLibrary, {requireDevIfEnabled = true})
		self.opponentLibrary = Opponent
	end
	if args.opponentDisplayLibrary then
		OpponentDisplay = Lua.import('Module:'.. self.args.opponentDisplayLibrary, {requireDevIfEnabled = true})
	end

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
		resolveOpponent = Logic.readBool(args.resolvePlayer or args.resolveTeam or DEFAULT_VALUES.resolveOpponent),
		gameIconsData = args.gameIcons,
		opponent = mw.text.decode(args.coach or args.player or args.team or mw.title.getCurrentTitle().baseText),
		opponentType = self:getOpponentType(),
		onlyAchievements = Logic.readBool(args.achievements),
		splitBy = args.splitBy or (not Logic.readBool(args.achievements) and 'year') or nil,
		splitSort = args.splitSort or DEFAULT_VALUES.splitSort,
	}

	config.sort = args.sort or
		(config.onlyAchievements and 'weight' or 'date')

	config.limit = tonumber(args.limit) or
		(config.onlyAchievements and 10 or 500)

	config.playerLimit =
		(config.opponentType == Opponent.solo and tonumber(args.playerLimit) or DEFAULT_VALUES.playerLimit)
		or (config.opponentType == COACH_TYPE and tonumber(args.coachLimit) or DEFAULT_VALUES.coachLimit)

	return config
end

function ResultsTable:getOpponentType()
	local args = self.args

	if args.opponenttype then
		local opponentType = TYPE_ALIASES[args.opponenttype:lower()]
		if opponentType then
			return opponentType
		end

		error('Invalid opponenttype "' .. args.opponenttype .. '"')
	end

	if args.coach then
		return COACH_TYPE
	elseif args.player then
		return Opponent.solo
	end

	return Opponent.team
end

-- todo (:create() call):
-- > query data
-- > build display from config and data

return ResultsTable
