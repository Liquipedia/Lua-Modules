---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Info = require('Module:Info')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:Matches Player')
local Namespace = require('Module:Namespace')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local PlayerIntroduction = require('Module:PlayerIntroduction/Custom')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class AgeofempiresInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

local RATINGCONFIG = {
	aoe2 = {
		{text = 'RM [[Age of Empires II/Definitive Edition|DE]]', id = 'aoe2net_id', game = 'aoe2de'},
		{
			text = Page.makeExternalLink('Tournament', 'https://aoe-elo.com/players'),
			id = 'aoe-elo.com_id',
			game = 'aoe-elo.com'
		},
		{text = 'RM [[Voobly]]', id = 'voobly_elo'},
	},
	aoe3 = {
		{text = 'Supremacy [[Age of Empires III/Definitive Edition|DE]]', id = 'aoe3net_id', game = 'aoe3de'},
		{text = 'Supremacy', id = 'aoe3_elo'},
	},
	aoe4 = {
		{text = 'QM', id = 'aoe4net_id', game = 'aoe4'},
	},
	aom = {
		{text = '[[Age of Mythology/Retold|Retold]]', id = 'aomr_id', game = 'aomr'},
		{text = 'Elo [[Voobly]]', id = 'aom_voobly_elo'},
		{text = 'Elo [[Age of Mythology/Extended Edition|AoM EE]]', id = 'aom_ee_elo'},
	}
}

local TALENT_ROLES = {'caster', 'analyst', 'host', 'expert', 'producer', 'director', 'journalist', 'observer'}

local MAX_NUMBER_OF_PLAYERS = 10
local INACTIVITY_THRESHOLD_PLAYER = {year = 1}
local INACTIVITY_THRESHOLD_BROADCAST = {month = 6}

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	local args = player.args

	-- Automatic achievements
	args.achievements = Achievements.player{player = player.pagename, noTemplate = true}

	-- Uppercase first letter in status
	if args.status then
		args.status = mw.getContentLanguage():ucfirst(args.status)
	end

	args.roleList = args.roles and Array.map(mw.text.split(args.roles, ','), function(role)
		return mw:getContentLanguage():ucfirst(mw.text.trim(role))
	end) or {}
	args.gameList = player:_getGames()

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		local _, roleType = CustomPlayer._getRoleType(args.roleList)

		autoPlayerIntro = PlayerIntroduction.run{
			player = player.pagename,
			transferquery = 'datapoint',
			defaultGame = 'Age of Empires II',
			team = args.team,
			name = args.romanized_name or args.name,
			first_name = args.first_name,
			last_name = args.last_name,
			status = args.status,
			game = mw.text.listToText(Array.map(args.gameList, function(game)
					return game.name .. (game.active and '' or '&nbsp;<small>(inactive)</small>')
				end)),
			type = roleType,
			role = args.roleList[1],
			role2 = args.roleList[2],
			id = args.id,
			idIPA = args.idIPA,
			idAudio = args.idAudio,
			birthdate = player.age.birthDateIso,
			deathdate = player.age.deathDateIso,
			nationality = args.country,
			nationality2 = args.country2,
			nationality3 = args.country3,
			subtext = args.subtext,
			freetext = args.freetext,
		}
	end

	return mw.html.create()
		:node(builtInfobox)
		:node(autoPlayerIntro)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			-- Games & Inactive Games
			Cell{name = 'Games', content = Array.map(args.gameList, function(game)
				return game.name .. (game.active and '' or '&nbsp;<small>(inactive)</small>')
			end)}
		)
		--Elo ratings
		local ratingCells = {}
		for game, ratings in Table.iter.spairs(RATINGCONFIG) do
			game = Game.raw{game = game}
			Array.forEach(ratings, function(rating)
				local content = {}
				local currentRating, bestRating
				if rating.game then
					currentRating, bestRating = caller:_getRating(rating.id, rating.game)
				else
					bestRating = args[rating.id]
				end
				if String.isNotEmpty(currentRating) then
					currentRating = currentRating .. '&nbsp;<small>(current)</small>'
					table.insert(content, currentRating)
				end
				if String.isNotEmpty(bestRating) then
					bestRating = bestRating .. '&nbsp;<small>(highest)</small>'
					table.insert(content, bestRating)
				end
				if Logic.isNotEmpty(content) then
					table.insert(ratingCells, Cell{name = rating.text .. ' (' .. game.abbreviation .. ')', content = content})
				end
			end)
		end
		if Logic.isNotEmpty(ratingCells) then
			table.insert(widgets, Title{children = 'Ratings'})
			Array.extendWith(widgets, ratingCells)
		end
	elseif id == 'status' then
		table.insert(widgets, Cell{
			name = 'Years Active',
			content = args.years_active and mw.text.split(args.years_active, ',') or {}
		})
	elseif id == 'role' then
		return {
			Cell{name = 'Roles', content =
				Array.map(args.roleList, function(role)
					return Page.makeInternalLink(role, ':Category:' .. role .. 's')
				end)
			}
		}
	elseif id == 'region' then
		return {}
	end
	return widgets
end

---@return string?
function CustomPlayer:createBottomContent()
	return MatchTicker.get{args = {self.pagename}}
end

---@param id string
---@param game string
---@return string? #not sure what `mw.ext.aoedb.currentrating` returns, but string makes sense
---@return string? #not sure what `mw.ext.aoedb.highestrating` returns, but string makes sense
function CustomPlayer:_getRating(id, game)
	if not self.args[id] then return end
	return mw.ext.aoedb.currentrating(self.args[id], game), mw.ext.aoedb.highestrating(self.args[id], game)
end

---@param roles string[]
---@return {player: boolean, coach: boolean, manager: boolean, talent: boolean}
---@return string?
function CustomPlayer._getRoleType(roles)
	local roleType = {
		player = Table.includes(roles, 'Player') or Table.isEmpty(roles),
		coach = Table.includes(roles, 'Coach'),
		manager = Table.includes(roles, 'Manager'),
		talent = false,
	}
	local primaryRole

	if roleType.manager or roleType.coach then
		primaryRole = 'staff'
	elseif roleType.player and Table.size(roles) == 1 then
		primaryRole = 'player'
	elseif Table.isNotEmpty(roles) then
		primaryRole = 'talent'
		roleType.talent = true
	end

	return roleType, primaryRole
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.region = Region.name{country = args.country}

	lpdbData.extradata.role = args.roleList[1]
	lpdbData.extradata.role2 = args.roleList[2]
	lpdbData.extradata.roles = mw.text.listToText(args.roleList)
	lpdbData.extradata.isplayer = CustomPlayer._getRoleType(args.roleList).player
	lpdbData.extradata.game = mw.text.listToText(Array.map(args.gameList, Operator.property('name')))
	Array.forEach(args.gameList,
		function(game, index)
			lpdbData.extradata['game' .. index] = game.name
		end
	)

	-- RelicLink IDs
	lpdbData.extradata.aoe2net_id = args.aoe2net_id
	lpdbData.extradata.aoe3net_id = args.aoe3net_id
	lpdbData.extradata.aoe4net_id = args.aoe4net_id

	return lpdbData
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local roles = CustomPlayer._getRoleType(self.args.roleList)

	Array.forEach(self.args.gameList, function(game)
		local gameName = game.name
		if not gameName then
			return
		end

		if roles.player then
			table.insert(categories, gameName .. ' Players')
		end
		if roles.talent then
			table.insert(categories, gameName .. ' Talent')
		end
	end)

	Array.forEach(self.args.roleList, function(role)
		if Table.includes(TALENT_ROLES, role:lower()) then
			table.insert(categories, mw.getContentLanguage():ucfirst(role) .. 's')
		end
	end)

	return categories
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local rolesType = CustomPlayer._getRoleType(args.roleList)
	if rolesType.player then
		return {store = 'Player', category = 'Player'}
	elseif rolesType.coach then
		return {store = 'Staff', category = 'Coache'}
	elseif rolesType.talent then
		return {store = 'Talent', category = 'Talent'}
	elseif rolesType.manager then
		return {store = 'Staff', category = 'Staff'}
	end

	return {store = 'Player', category = 'Player'}
end

---@return {name: string, active: boolean}[]
function CustomPlayer:_getGames()
	local args = self.args

	-- Games from placements
	local games = self:_queryGames()

	-- Games from broadcasts
	local broadcastGames = self:_getBroadcastGames()
	Array.extendWith(games, Array.filter(broadcastGames,
		function(entry)
			return not Array.any(games, function(e) return e.game == entry.game end)
		end
	))

	-- Games entered manually
	local manualGames = args.games and Array.map(
		mw.text.split(args.games, ','),
		function(game)
			return {game = Game.name{game = mw.text.trim(game), useDefault = false}}
		end
	) or {}
	Array.extendWith(games, Array.filter(manualGames,
		function(entry)
			return not Array.any(games, function(e) return e.game == entry.game end)
		end
	))

	-- Games entered manually as inactive
	local manualInactiveGames = args.games_inactive and Array.map(
		mw.text.split(args.games_inactive, ','),
		function(game)
			return {game = Game.name{game = mw.text.trim(game), useDefault = false}}
		end
	) or {}
	Array.extendWith(games, Array.filter(manualInactiveGames,
		function(entry)
			return not Array.any(games, function(e) return e.game == entry.game end)
		end
	))

	Array.sortInPlaceBy(games, function(entry) return entry.game end)

	local placementThreshold = CustomPlayer._calculateDateThreshold(INACTIVITY_THRESHOLD_PLAYER)
	local broadcastThreshold = CustomPlayer._calculateDateThreshold(INACTIVITY_THRESHOLD_BROADCAST)

	local isActive = function(game)
		if Array.any(manualInactiveGames, function(g) return g.game == game end) then
			return false
		end
		if Array.any(broadcastGames, function(g) return g.game == game and g.date >= broadcastThreshold end) then
			return true
		end
		local placement = self:_getLatestPlacement(game)
		return placement and placement.date and placement.date >= placementThreshold
	end

	games = Array.filter(Array.map(
		games,
		function(entry)
			if String.isEmpty(entry.game) then
				return {}
			end
			return {name = entry.game, active = isActive(entry.game)}
		end),
		Table.isNotEmpty
	)

	return games
end

---@param thresholdConfig table
---@return string|osdate
function CustomPlayer._calculateDateThreshold(thresholdConfig)
	local dateThreshold = os.date('!*t')
	for key, value in pairs(thresholdConfig) do
		dateThreshold[key] = dateThreshold[key] - value
	end
	return os.date('!%F', os.time(dateThreshold --[[@as osdateparam]]))
end

---@return placement[]
function CustomPlayer:_queryGames()
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = self:_buildPlacementConditions():toString(),
		query = 'game',
		groupby = 'game asc',
	})

	if type(data) ~= 'table' then
		error(data)
	end

	return data
end

---@param game string
---@return placement
function CustomPlayer:_getLatestPlacement(game)
	local conditions = ConditionTree(BooleanOperator.all):add{
		self:_buildPlacementConditions(),
		ConditionNode(ColumnName('game'), Comparator.eq, game)
	}
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions:toString(),
		query = 'date',
		order = 'date desc',
		limit = 1
	})

	if type(data) ~= 'table' then
		error(data)
	end
	return data[1]
end

---@return ConditionTree
function CustomPlayer:_buildPlacementConditions()
	local person = self:_getPersonQuery()

	local opponentConditions = ConditionTree(BooleanOperator.any)

	local prefix = 'p'
	for playerIndex = 1, MAX_NUMBER_OF_PLAYERS do
		opponentConditions:add{
			ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex), Comparator.eq, person),
			ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex), Comparator.eq, person:gsub(' ', '_')),
		}
	end

	return opponentConditions
end

---@return {game: string, date: string}[]
function CustomPlayer:_getBroadcastGames()
	local person = self:_getPersonQuery()
	local personCondition = ConditionTree(BooleanOperator.any)
		:add{
			ConditionNode(ColumnName('page'), Comparator.eq, person),
			ConditionNode(ColumnName('page'), Comparator.eq, person:gsub(' ', '_')),
		}
	local games = {}

	for _, gameInfo in pairs(Info.games) do
		local conditions = ConditionTree(BooleanOperator.all)
			:add{
				personCondition,
				ConditionNode(ColumnName('extradata_game'), Comparator.eq, gameInfo.name)
			}
		local data = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			conditions = conditions:toString(),
			query = 'date',
			order = 'date desc',
			limit = 1
		})

		if type(data) ~= 'table' then
			error(data)
		end

		if data[1] then
			table.insert(games, {game = gameInfo.name, date = data[1].date})
		end
	end
	return games
end

---@return string
function CustomPlayer:_getPersonQuery()
	if Namespace.isMain() then
		return self.pagename
	else
		return mw.ext.TeamLiquidIntegration.resolve_redirect(self.args.id)
	end
end

return CustomPlayer
