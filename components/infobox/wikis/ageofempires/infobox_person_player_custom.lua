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
local PlayerIntroduction = require('Module:PlayerIntroduction')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CustomPlayer = Class.new()

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
		{text = 'Elo [[Voobly]]', id = 'aom_voobly_elo'},
		{text = 'Elo [[Age of Mythology/Extended Edition|AoM EE]]', id = 'aom_ee_elo'},
	}
}

local TALENT_ROLES = {'caster', 'analyst', 'host', 'expert', 'producer', 'director', 'journalist', 'observer'}

local _player
local _args

local MAX_NUMBER_OF_PLAYERS = 10
local INACTIVITY_THRESHOLD_PLAYER = {year = 1}
local INACTIVITY_THRESHOLD_BROADCAST = {month = 6}

function CustomPlayer.run(frame)
	_player = Player(frame)
	_args = _player.args
	_args.autoTeam = true
	local automatedHistory = TeamHistoryAuto.results{player=_player.pagename, convertrole=true, addlpdbdata=true}
	if String.isEmpty(_args.history) then
		_args.history = automatedHistory
	else
		_args.history = tostring(mw.html.create('div')
			:addClass("show-when-logged-in")
			:addClass("navigation-not-searchable")
			:tag('big'):wikitext("Automated History"):done()
			:wikitext(automatedHistory)
			:tag('big'):wikitext("Manual History"):done())
			.. _args.history
	end

	-- Automatic achievements
	_args.achievements = Achievements.player{player = _player.pagename, noTemplate = true}

	-- Uppercase first letter in status
	if _args.status then
		_args.status = mw.getContentLanguage():ucfirst(_args.status)
	end

	_args.roleList = _args.roles and Array.map(mw.text.split(_args.roles, ','), function(role)
		return mw:getContentLanguage():ucfirst(mw.text.trim(role))
	end) or {}
	_args.gameList = CustomPlayer._getGames()

	_player.adjustLPDB = CustomPlayer.adjustLPDB
	_player.createWidgetInjector = CustomPlayer.createWidgetInjector
	_player.getPersonType = CustomPlayer.getPersonType
	_player.getWikiCategories = CustomPlayer.getWikiCategories
	_player.createBottomContent = CustomPlayer.createBottomContent

	local builtInfobox = _player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((_args.autoPI or ''):lower()) then
		local _, roleType = CustomPlayer._getRoleType(_args.roleList)

		autoPlayerIntro = PlayerIntroduction.run{
			player = _player.pagename,
			transferquery = 'datapoint',
			defaultGame = 'Age of Empires II',
			team = _args.team,
			name = _args.romanized_name or _args.name,
			first_name = _args.first_name,
			last_name = _args.last_name,
			status = _args.status,
			game = mw.text.listToText(Array.map(_args.gameList, function(game)
					return game.name .. (game.active and '' or '&nbsp;<small>(inactive)</small>')
				end)),
			type = roleType,
			role = _args.roleList[1],
			role2 = _args.roleList[2],
			id = _args.id,
			idIPA = _args.idIPA,
			idAudio = _args.idAudio,
			birthdate = Variables.varDefault('player_birthdate'),
			deathdate = Variables.varDefault('player_deathdate'),
			nationality = _args.country,
			nationality2 = _args.country2,
			nationality3 = _args.country3,
			subtext = _args.subtext,
			freetext = _args.freetext,
		}
	end

	return builtInfobox .. autoPlayerIntro
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets, Cell{
			name = 'Years Active',
			content = _args.years_active and mw.text.split(_args.years_active, ',') or {}
		})
	elseif id == 'role' then
		return {
			Cell{name = 'Roles', content =
				Array.map(_args.roleList, function(role)
					return Page.makeInternalLink(role, ':Category:' .. role .. 's')
				end)
			}
		}
	elseif id == 'region' then
		return {}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	-- Games & Inactive Games
	table.insert(widgets, Cell{
		name = 'Games',
		content = Array.map(
				_args.gameList,
				function(game)
					return game.name .. (game.active and '' or '&nbsp;<small>(inactive)</small>')
				end
		)
	})
	--Elo ratings
	table.insert(widgets, Title{name = 'Ratings'})
	for game, ratings in Table.iter.spairs(RATINGCONFIG) do
		game = Game.raw{game = game}
		for _, rating in ipairs(ratings) do
			local content = {}
			local currentRating, bestRating
			if rating.game then
				currentRating, bestRating = CustomPlayer.getRating(rating.id, rating.game)
			else
				bestRating = _args[rating.id]
			end
			if String.isNotEmpty(currentRating) then
				currentRating = currentRating .. '&nbsp;<small>(current)</small>'
				table.insert(content, currentRating)
			end
			if String.isNotEmpty(bestRating) then
				bestRating = bestRating .. '&nbsp;<small>(highest)</small>'
				table.insert(content, bestRating)
			end
			table.insert(widgets, Cell{name = rating.text .. ' (' .. game.abbreviation .. ')', content = content})
		end
	end
	return widgets
end

function CustomPlayer.createBottomContent()
	return MatchTicker.get{args = {_player.pagename}}
end

function CustomPlayer.getRating(id, game)
	if _args[id] then
		return mw.ext.aoedb.currentrating(_args[id], game), mw.ext.aoedb.highestrating(_args[id], game)
	end
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

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

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.region = Region.name{country = _args.country}

	lpdbData.extradata.role = _args.roleList[1]
	lpdbData.extradata.role2 = _args.roleList[2]
	lpdbData.extradata.roles = mw.text.listToText(_args.roleList)
	lpdbData.extradata.isplayer = CustomPlayer._getRoleType(_args.roleList).player
	lpdbData.extradata.game = mw.text.listToText(Array.map(_args.gameList, Operator.property('name')))
	Array.forEach(_args.gameList,
		function(game, index)
			lpdbData.extradata['game' .. index] = game.name
		end
	)

	-- RelicLink IDs
	lpdbData.extradata.aoe2net_id = _args.aoe2net_id
	lpdbData.extradata.aoe3net_id = _args.aoe3net_id
	lpdbData.extradata.aoe4net_id = _args.aoe4net_id

	return lpdbData
end

function CustomPlayer:getWikiCategories(categories)
	local roles = CustomPlayer._getRoleType(_args.roleList)

	Array.forEach(_args.gameList, function(game)
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

	Array.forEach(_args.roleList, function(role)
		if Table.includes(TALENT_ROLES, role:lower()) then
			table.insert(categories, mw.getContentLanguage():ucfirst(role) .. 's')
		end
	end)

	return categories
end

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

function CustomPlayer._getGames()
	-- Games from placements
	local games = CustomPlayer._queryGames()

	-- Games from broadcasts
	local broadcastGames = CustomPlayer._getBroadcastGames()
	Array.extendWith(games, Array.filter(broadcastGames,
		function(entry)
			return not Array.any(games, function(e) return e.game == entry.game end)
		end
	))

	-- Games entered manually
	local manualGames = _args.games and Array.map(
		mw.text.split(_args.games, ','),
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
	local manualInactiveGames = _args.games_inactive and Array.map(
		mw.text.split(_args.games_inactive, ','),
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
		local placement = CustomPlayer._getLatestPlacement(game)
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

function CustomPlayer._calculateDateThreshold(thresholdConfig)
	local dateThreshold = os.date('!*t')
	for key, value in pairs(thresholdConfig) do
		dateThreshold[key] = dateThreshold[key] - value
	end
	return os.date('!%F', os.time(dateThreshold --[[@as osdateparam]]))
end

function CustomPlayer._queryGames()
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = CustomPlayer._buildPlacementConditions():toString(),
		query = 'game',
		groupby = 'game asc',
	})

	if type(data) ~= 'table' then
		error(data)
	end

	return data
end

function CustomPlayer._getLatestPlacement(game)
	local conditions = ConditionTree(BooleanOperator.all):add{
		CustomPlayer._buildPlacementConditions(),
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

function CustomPlayer._buildPlacementConditions()
	local person = CustomPlayer._getPersonQuery()

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

function CustomPlayer._getBroadcastGames()
	local person = CustomPlayer._getPersonQuery()
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

function CustomPlayer._getPersonQuery()
	if Namespace.isMain() then
		return _player.pagename
	else
		return mw.ext.TeamLiquidIntegration.resolve_redirect(_args.id)
	end
end

return CustomPlayer
