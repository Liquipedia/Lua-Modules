---
-- for @Liquipedia by @hjpalpha
-- page=Module:TeamList/Starcraft/TeamCard
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Variables = Lua.import('Module:Variables')

local PlayerExt = Lua.import('Module:Player/Ext')
local PlayerExtCustom = Lua.import('Module:Player/Ext/Custom')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Opponent = Lua.import('Module:Opponent/Custom')

-- can't use the DateExt function
-- due to the wiki vars not existing if using subst bot run
local getContextualDateOrNow = function()
	local date = Variables.varDefault('tournament_enddate')
		or Variables.varDefault('tournament_startdate')

	if Logic.isNotEmpty(date) then return date end

	local pageName = mw.title.getCurrentTitle().prefixedText:gsub(' ', '_')

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '.[[pagename::' .. pageName .. ']]',
		query = 'startdate, enddate',
		limit = 1,
	})[1] or {}

	return Logic.nilIfEmpty(data.enddate)
		or Logic.nilIfEmpty(data.startdate)
		or os.date('%F') --[[@as string]]
end

---@class StarcraftTeamCard
---@operator call(table): StarcraftTeamCard
---@field args table
---@field config StarcraftTeamCardConfig
---@field opponent StarcraftTeamCardOpponent
---@field name string
---@field root Html?
local TeamCard = Class.new(
	function(self, args)
		self.args = args
		self.opponent = self:readOpponent()
		local opponentName = Opponent.toName(self.opponent)
		assert(opponentName, 'Missing Team Template for "' .. (args.team or '') .. '"')
		self.name = opponentName:gsub(' ', '_')
	end
)

---@class StarcraftTeamCardOpponent: StarcraftStandardOpponent
---@field players StarcraftTeamCardPlayer[]
---@field note string?
---@field dq boolean
---@field subtitle string?
---@field date string

---@return StarcraftTeamCardOpponent
function TeamCard:readOpponent()
	local args = self.args
	local date = args.date or getContextualDateOrNow()
	local team = (args.team or 'tbd'):lower():gsub('_', ' ')
	local opponent = Opponent.resolve(
		Opponent.readOpponentArgs{team, type = Opponent.team}, date
	) --[[@as StarcraftTeamCardOpponent]]

	opponent.dq = Logic.readBool(args.dq)
	opponent.date = date
	opponent.note = args.note

	opponent.players = Array.extractValues(Table.mapArgumentsByPrefix(args, {'p', 'player'}, function(key, index)
		return self:readPlayer(key, index, date)
	end))

	if #opponent.players >= 35 then
		mw.ext.TeamLiquidItegration.add_category('TeamCards with 35 players')
	elseif #opponent.players >= 25 then
		mw.ext.TeamLiquidIntegration.add_category('TeamCards with 25 players')
	elseif #opponent.players >= 20 then
		mw.ext.TeamLiquidIntegration.add_category('TeamCards with 20 players')
	end

	return opponent
end

---@class StarcraftTeamCardPlayer: StarcraftStandardPlayer
---@field ace boolean?
---@field captain boolean?
---@field dnp boolean?
---@field dq boolean?
---@field joker boolean?
---@field mainTeam string?
---@field mainTeamPage string?
---@field note boolean?
---@field tag string?
---@field tagTitle string?
---@field two boolean?
---@field withdraw boolean?

---@param key any
---@param index integer
---@param date string
---@return StarcraftTeamCardPlayer
function TeamCard:readPlayer(key, index, date)
	local args = self.args

	local getArg = function(field)
		return args['p' .. index .. field] or args[field .. index]
	end

	local mainTeamInput = getArg('team')
	if mainTeamInput and mainTeamInput:lower() == 'noteam' then
		mainTeamInput = nil
	end

	local mainTeam, mainTeamPage
	if mainTeamInput then
		mainTeam = TeamTemplate.resolve(mainTeamInput, date)
		assert(mainTeam, 'missing team template "' .. mainTeamInput .. '"')
		mainTeamPage = TeamTemplate.getPageName(mainTeam) or nil
	end

	return {
		displayName = args[key],
		flag = String.nilIfEmpty(Flags.CountryName{flag = getArg('flag')}),
		pageName = getArg('link'),
		faction = Faction.read(getArg('faction') or getArg('race')),

		ace = Logic.readBoolOrNil(getArg('ace')),
		captain = Logic.readBoolOrNil(getArg('captain')),
		dnp = Logic.readBoolOrNil(getArg('dnp')),
		dq = Logic.readBoolOrNil(getArg('dq') or getArg('out')),
		joker = Logic.readBoolOrNil(getArg('joker')),
		mainTeam = mainTeam,
		mainTeamPage = mainTeamPage,
		note = getArg('note'),
		tag = getArg('tag'),
		tagTitle = getArg('tagTitle'),
		two = Logic.readBoolOrNil(getArg('two')),
		withdraw = Logic.readBoolOrNil(getArg('withdraw')),
	}
end

---@class StarcraftTeamCardConfig
---@field cardWidth string
---@field teamStyle string?
---@field showFlags boolean
---@field display boolean
---@field collapsed boolean
---@field collapsible boolean?
---@field autoDnp boolean
---@field syncPlayers boolean
---@field resolveDate string
---@field sortPlayers boolean
---@field noStorage boolean
---@field isAdhoc boolean?

---@param parentConfig StarcraftTeamListConfig?
---@return self
function TeamCard:getConfig(parentConfig)
	self.config = TeamCard.readConfig(self.args, parentConfig)

	return self
end

---@param args table
---@param parentConfig StarcraftTeamListConfig?
---@return StarcraftTeamListConfig
function TeamCard.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}

	local width = tonumber(args.cardWidth or args.width)

	return {
		--display
		cardWidth = width and (width .. 'px') or args.cardWidth or args.width or parentConfig.cardWidth or '240px',
		teamStyle = Logic.readBool(args.short) and 'short' or parentConfig.teamStyle,
		showFlags = Logic.nilOr(Logic.readBoolOrNil(args.showFlags), parentConfig.showFlags, true),
		display = not Logic.readBool(args.hidden),
		collapsed =Logic.nilOr(Logic.readBoolOrNil(args.collapsed), not Logic.readBoolOrNil(args.uncollapsed)),
		collapsible = Logic.nilOr(Logic.readBoolOrNil(args.collapsible), parentConfig.collapsible, true),
		--sync
		autoDnp = Logic.nilOr(Logic.readBoolOrNil(args.autoDnp), parentConfig.autoDnp, true),
		syncPlayers = Logic.nilOr(Logic.readBoolOrNil(args.syncPlayers), parentConfig.syncPlayers, true),
		resolveDate = args.date or parentConfig.resolveDate or getContextualDateOrNow(),
		sortPlayers = Logic.nilOr(Logic.readBoolOrNil(args.sortPlayers), parentConfig.sortPlayers, true),
		--storage
		noStorage = Logic.readBool(args.noStorage or parentConfig.noStorage or
			Lpdb.isStorageDisabled() or not Namespace.isMain()),
		isAdhoc = Logic.nilOr(Logic.readBoolOrNil(args.adhoc), parentConfig.isAdhoc),
	}
end

---@param parentMatchGroupSpec {matchGroupIds: string[], pageNames: string[]}?
---@return self
function TeamCard:sync(parentMatchGroupSpec)
	local config = self.config

	local players = self.opponent.players

	if Table.isEmpty(players) then
		return self
	end

	local date = self.opponent.date

	if config.syncPlayers then
		players = Array.map(players, function(player)
			player = Table.merge(player, PlayerExtCustom.syncPlayer(player, {date = date}))
			player.pageName = player.pageName:gsub(' ', '_')
			player.mainTeam = config.isAdhoc and PlayerExt.syncTeam(player.pageName, player.mainTeam, {}) or player.mainTeam
			player.mainTeamPage = player.mainTeamPage or
				player.mainTeam and TeamTemplate.getPageName(TeamTemplate.resolve(player.mainTeam, date) --[[@as string]]) or
				nil

			return player
		end)
	end

	if config.autoDnp then
		local matchGroupSpec = parentMatchGroupSpec or TournamentStructure.currentPageSpec()
		players = self:dnp(players, matchGroupSpec)
	end

	if config.sortPlayers then
		Array.sortInPlaceBy(players, function(player) return player.displayName:lower() end)
	end

	self.opponent.players = players

	return self
end

---@param players StarcraftTeamCardPlayer[]
---@param matchGroupSpec {matchGroupIds: string[], pageNames: string[]}
---@return StarcraftTeamCardPlayer[]
function TeamCard:dnp(players, matchGroupSpec)
	local dnpData = TeamCard.fetchDnp(matchGroupSpec)

	Array.forEach(players, function(player)
		player.dnp = player.dnp or (dnpData[self.name] and not dnpData[self.name][player.pageName])
	end)

	return players
end

TeamCard.fetchDnp = FnUtil.memoize(function(matchGroupSpec)
	return TeamCard.fetchDnpData(matchGroupSpec)
end)

---@param matchGroupSpec {matchGroupIds: string[], pageNames: string[]}
---@return table<string, table<string, boolean>>
function TeamCard.fetchDnpData(matchGroupSpec)
	local matchRecords = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(TournamentStructure.getMatch2Filter(matchGroupSpec)),
		query = 'pagename, match2bracketdata, match2opponents, winner, match2games',
		order = 'date asc',
		limit = 5000,
	})

	local playersByTeam = {}
	Array.forEach(matchRecords, function(matchRecord)
		local teams = Array.map(matchRecord.match2opponents, function(opponent, opponentIndex)
			playersByTeam[opponent.name] = playersByTeam[opponent.name] or {}
			return {name = opponent.name, players = Array.map(opponent.match2players, function(player) return player.name end)}
		end)

		Array.forEach(matchRecord.match2games, function(game)
			local gameOpponents = game.opponents
			if type(gameOpponents) ~= 'table' then
				gameOpponents = Json.parseIfTable(gameOpponents) or {}
			end
			Array.forEach(gameOpponents, function(opp, opponentIndex)
				for playerIndex, player in pairs(opp.players or {}) do
					if Logic.isNotEmpty(player) then
						local matchPlayer = teams[opponentIndex].players[playerIndex]
						if player then
							playersByTeam[teams[opponentIndex].name][matchPlayer] = true
						end
					end
				end
			end)
		end)
	end)

	return playersByTeam
end

return TeamCard
