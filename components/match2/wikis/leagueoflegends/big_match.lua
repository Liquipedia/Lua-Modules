---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:BigMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local HeroIcon = require('Module:ChampionIcon')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')
local Match = require('Module:Match')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine')
local VodLink = require('Module:VodLink')

local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local Template = Lua.import('Module:BigMatch/Template', {requireDevIfEnabled = true})
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific', {requireDevIfEnabled = true})

local BigMatch = {}

local KEYSTONES = Table.map({
	-- Precision
	'Press the Attack',
	'Lethal Tempo',
	'Fleet Footwork',
	'Conqueror',

	-- Domination
	'Electrocute',
	'Predator',
	'Dark Harvest',
	'Hail of Blades',

	-- Sorcery
	'Summon Aery',
	'Arcane Comet',
	'Phase Rush',

	-- Resolve
	'Grasp of the Undying',
	'Aftershock',
	'Guardian',

	-- Inspiration
	'Glacial Augment',
	'Unsealed Spellbook',
	'First Strike',
}, function (_, value)
	return value, true
end)

local ROLE_ORDER = Table.map({
	'top',
	'jungle',
	'middle',
	'bottom',
	'support',
}, function (key, value)
	return value, key
end)

local NOT_PLAYED = 'np'
local DEFAULT_ITEM = 'EmptyIcon'
local TEAMS = Array.range(1, 2)

function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)

	args = BigMatch._contextualEnrichment(args)

	local model = BigMatch._match2Director(args)

	model.isBestOfOne = #model.games == 1
	model.dateCountdown = DisplayHelper.MatchCountdownBlock(model)

	-- Create an object array for links
	model.links = Array.extractValues(Table.map(model.links, function (site, link)
		return site, Table.mergeInto({link = link}, MatchLinks[site])
	end))

	-- Add more opponent data field
	Array.forEach(model.opponents, function (opponent, index)
		local teamTemplate = mw.ext.TeamTemplate.raw(opponent.template)

		opponent.opponentIndex = index
		opponent.iconDisplay = mw.ext.TeamTemplate.teamicon(opponent.template)
		opponent.shortname = teamTemplate.shortname
		opponent.page = teamTemplate.page
		opponent.name = teamTemplate.name
	end)

	-- Enrich game information
	Array.forEach(model.games, function (game, index)
		game.apiInfo = model['map' .. index] or {}

		if not game.apiInfo.team1 or not game.apiInfo.team2 then
			return
		end

		game.apiInfo.team1.scoreDisplay = game.winner == 1 and 'W' or game.winner == 2 and 'L' or '-'
		game.apiInfo.team2.scoreDisplay = game.winner == 2 and 'W' or game.winner == 1 and 'L' or '-'

		Array.forEach(TEAMS, function(teamIdx)
			local team = game.apiInfo['team' .. teamIdx]

			Array.forEach(team.players, function(player)
				player.roleIcon = player.role .. ' ' .. team.color
				player.runeKeystone = Array.filter(player.runeData.primary.runes, function(rune)
					return KEYSTONES[rune]
				end)[1]
				player.runeSecondaryTree = player.runeData.secondary.tree
				player.items = Array.map(Array.range(1, 6), function (idx)
					return player.items[idx] or DEFAULT_ITEM
				end)
				player.damageDone = BigMatch._abbreviateNumber(player.damageDone)
			end)

			-- Aggregate stats
			team.gold = BigMatch._abbreviateNumber(BigMatch._sumItem(team.players, 'gold'))
			team.kills = BigMatch._sumItem(team.players, 'kills')
			team.deaths = BigMatch._sumItem(team.players, 'deaths')
			team.assists = BigMatch._sumItem(team.players, 'assists')
		end)

		local _
		_, game.apiInfo.championVetoByTeam = Array.groupBy(game.apiInfo.championVeto, Operator.property('team'))

		Array.forEach(game.apiInfo.championVetoByTeam, function (team)
			local lastType = 'ban'
			Array.forEach(team, function(veto)
				veto.isBan = veto.type == 'ban'
				veto.isNewGroup = lastType ~= veto.type
				lastType = veto.type
			end)
		end)
	end)

	model.vods = {
		icons = Array.map(model.games, function(game, gameIdx)
			return game.vod and VodLink.display{
				gamenum = gameIdx,
				vod = game.vod,
			} or ''
		end)
	}

	model.generateSeriesDots = function(self)
		return table.concat(Array.map(model.games, function (game)
			if not game.apiInfo['team' .. self.opponentIndex] then
				return ''
			end
			return game.apiInfo['team' .. self.opponentIndex].scoreDisplay
		end), ' ')
	end
	model.heroIcon = function(self)
		local champion = type(self) == 'table' and self.champion or self
		return HeroIcon._getImage{champion, date = model.date}
	end

	return BigMatch.render(model)
end

function BigMatch._sumItem(tbl, item)
	return Array.reduce(Array.map(tbl, Operator.property(item)), Operator.add)
end

function BigMatch._abbreviateNumber(number)
	return string.format('%.1fK', number / 1000)
end

function BigMatch._contextualEnrichment(args)
	-- Retrieve tournament info from the bracket/matchlist
	if String.isEmpty(args.tournamentlink) then
		args.tournamentlink = BigMatch._fetchTournamentPageFromMatch{BigMatch._getId()}
	end

	local tournamentData = BigMatch._fetchTournamentInfo(args.tournamentlink)

	args.patch = args.patch or tournamentData.patch
	args.tournament =  args.tournament or tournamentData.name
	args.parent = args.tournamentlink or tournamentData.pagename

	return args
end

function BigMatch._match2Director(args)
	local matchData = {}

	matchData.date = args.date
	matchData.patch = args.patch
	matchData.opponent1 = Json.parseIfString(args.opponent1)
	matchData.opponent2 = Json.parseIfString(args.opponent2)

	local prefixWithKey = function(tbl, prefix)
		local prefixKey = function(key, value)
			return prefix .. key, value
		end
		return Table.map(tbl, prefixKey)
	end

	local maps = Array.mapIndexes(function(gameIndex)
		local mapInput = Json.parseIfString(args['map' .. gameIndex])

		if not mapInput then
			return
		end

		-- If no matchid is provided, assume this as a normal map
		if not mapInput.matchid then
			return mapInput
		end

		local map = mw.ext.LeagueOfLegendsDB.getData(mapInput.matchid, Logic.readBool(mapInput.reversed))

		-- Match not found on the API
		assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')

		-- Convert seconds to minutes and seconds
		map.length = map.length and (math.floor(map.length / 60) .. ':' .. (map.length % 60)) or nil

		Array.forEach(TEAMS, function(teamIdx)
			local team = map['team' .. teamIdx]

			map['team' .. teamIdx .. 'side'] = team.color

			-- Sort players based on role
			Array.sortInPlaceBy(team.players, function (player)
				return ROLE_ORDER[player.role]
			end)
		end)

		-- Break down the picks and bans into per team, per type, in order.
		Array.sortInPlaceBy(map.championVeto, Operator.property('vetoNumber'))

		local _, vetoesByTeam = Array.groupBy(map.championVeto, Operator.property('team'))

		-- TODO: have picks sorted on role, bans sorted on number
		Table.mergeInto(map, prefixWithKey(Array.map(vetoesByTeam, function (team)
			return Table.mapValues(Table.groupBy(team, function(_, veto)
				return veto.type
			end), function (vetoType)
				return Array.extractValues(Table.mapValues(vetoType, Operator.property('champion')))
			end)
		end), 't'))

		return map
	end)

	Table.mergeInto(matchData, prefixWithKey(maps, 'map'))
	local match2input = Table.merge(args, Table.deepCopy(matchData))

	local match = CustomMatchGroupInput.processMatch(match2input, {isStandalone = true})

	local bracketId, matchId = BigMatch._getId()
	match.bracketid, match.matchid = 'MATCH_' .. bracketId, matchId

	-- Don't store match1 as BigMatch records are not complete
	Match.store(match, {storeMatch1 = false, storeSmw = false})

	return Table.merge(matchData, WikiSpecific.matchFromRecord(match))
end

function BigMatch.render(model)
	return mw.html.create('div')
		:wikitext(BigMatch.header(model))
		:wikitext(BigMatch.games(model))
		:wikitext(BigMatch.footer(model))
end

function BigMatch.header(model)
	return TemplateEngine():render(Template.header, model)
end

function BigMatch.games(model)
	local games = Array.map(Array.filter(model.games, function (game)
		return game.resulttype ~= NOT_PLAYED
	end), function (game)
		return TemplateEngine():render(Template.game, Table.merge(model, game))
	end)

	if #games < 2 then
		return tostring(games[1])
	end

	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	Array.forEach(games, function (game, idx)
		tabs['name' .. idx] = 'Game ' .. idx
		tabs['content' .. idx] = tostring(game)
	end)

	return Tabs.dynamic(tabs)
end

function BigMatch.footer(model)
	return TemplateEngine():render(Template.footer, model)
end

function BigMatch._getId()
	local title = mw.title.getCurrentTitle().text

	-- Title format is `ID bracketID matchID`
	local titleParts = mw.text.split(title, ' ')

	-- Return bracketID and matchID
	return titleParts[2], titleParts[3]
end

function BigMatch._fetchTournamentInfo(page)
	if not page then
		return {}
	end

	return mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'pagename, name, patch',
		conditions = '[[pagename::'.. page .. ']]',
	})[1] or {}
end

function BigMatch._fetchTournamentPageFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
		limit = 1,
	})[1] or {}
	return data.parent
end

return BigMatch
