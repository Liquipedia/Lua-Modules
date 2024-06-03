---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:BigMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local DateExt = require('Module:Date/Ext')
local ChampionNames = mw.loadData('Module:ChampionNames')
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

local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HiddenDataBox = Lua.import('Module:HiddenDataBox/Custom')
local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Template = Lua.import('Module:BigMatch/Template')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local NO_CHARACTER = 'default'

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
local AVAILABLE_FOR_TIERS = {1, 2, 3}

local BIG_MATCH_START_TIME = 1619827201 -- May 1st 2021 midnight

---@param match table
---@return boolean
function BigMatch.isEnabledFor(match)
	return Table.includes(AVAILABLE_FOR_TIERS, tonumber(match.liquipediatier))
			and (match.timestamp == DateExt.defaultTimestamp or match.timestamp > BIG_MATCH_START_TIME)
end

---@param frame Frame
---@return Html
function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)

	args = BigMatch._contextualEnrichment(args)
	HiddenDataBox.run(args) -- Set wiki variables used by match2

	local model = BigMatch._match2Director(args)

	model.isBestOfOne = #model.games == 1
	model.dateCountdown = model.timestamp ~= DateExt.defaultTimestamp and
		DisplayHelper.MatchCountdownBlock(model) or nil

	-- Create an object array for links
	model.links = Array.extractValues(Table.map(model.links, function (site, link)
		return site, Table.mergeInto({link = link}, MatchLinks[site])
	end))

	-- Add more opponent data field
	Array.forEach(model.opponents, function (opponent, index)
		opponent.opponentIndex = index

		if not opponent.template or not mw.ext.TeamTemplate.teamexists(opponent.template) then
			return
		end
		local teamTemplate = mw.ext.TeamTemplate.raw(opponent.template)

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
		local champion = self
		if type(self) == 'table' then
			champion = self.champion
			---@cast champion -table
		end
		return CharacterIcon.Icon{
			character = champion or NO_CHARACTER,
			date = model.date
		}
	end

	return BigMatch.render(model)
end

---@param tbl table
---@param item string
---@return number
function BigMatch._sumItem(tbl, item)
	return Array.reduce(Array.map(tbl, Operator.property(item)), Operator.add, 0)
end

---@param number number|string
---@return string
function BigMatch._abbreviateNumber(number)
	return string.format('%.1fK', number / 1000)
end

---@param args table
---@return table
function BigMatch._contextualEnrichment(args)
	-- Retrieve tournament info from the bracket/matchlist
	if String.isEmpty(args.tournamentlink) then
		args.tournamentlink = BigMatch._fetchTournamentPageFromMatch{BigMatch._getId()}
	end

	local tournamentData = BigMatch._fetchTournamentInfo(args.tournamentlink)

	args.patch = args.patch or tournamentData.patch
	args.tournament = args.tournament or tournamentData.name
	args.parent = args.tournamentlink or tournamentData.pagename

	return args
end

---@param args table
---@return table
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

		BigMatch._cleanChampions(map)

		-- Convert seconds to minutes and seconds
		map.length = map.length and (math.floor(map.length / 60) .. ':' .. string.format('%02d', map.length % 60)) or nil

		-- Break down the picks and bans into per team, per type, in order.
		Array.sortInPlaceBy(map.championVeto, Operator.property('vetoNumber'))

		local _, vetoesByType = Array.groupBy(map.championVeto, Operator.property('type'))
		local _, bansPerTeam = Array.groupBy(vetoesByType.ban or {}, Operator.property('team'))

		Array.forEach(TEAMS, function(teamIdx)
			local team = map['team' .. teamIdx]

			map['team' .. teamIdx .. 'side'] = team.color
			team.players = team.players or {}

			-- Sort players based on role
			Array.sortInPlaceBy(team.players, function (player)
				return ROLE_ORDER[player.role]
			end)

			team.ban = Array.map(bansPerTeam[teamIdx], Operator.property('champion'))
			team.pick = Array.map(team.players, Operator.property('champion'))
		end)

		return map
	end)

	Table.mergeInto(matchData, prefixWithKey(maps, 'map'))
	local match2input = Table.merge(args, Table.deepCopy(matchData))

	local match = CustomMatchGroupInput.processMatch(match2input, {isStandalone = true})
	for mapKey, map in Table.iter.pairsByPrefix(match, 'map') do
		match[mapKey] = MatchGroupInput.getCommonTournamentVars(map, match)
	end

	local bracketId, matchId = BigMatch._getId()
	match.bracketid, match.matchid = 'MATCH_' .. bracketId, matchId

	-- Don't store match1 as BigMatch records are not complete
	Match.store(match, {storeMatch1 = false})

	return Table.merge(matchData, WikiSpecific.matchFromRecord(match))
end

---@param map table
function BigMatch._cleanChampions(map)
	local cleanChampion = function(champion)
		return ChampionNames[champion and champion:lower()]
	end

	Array.forEach(map.championVeto or {}, function(veto)
		veto.champion = cleanChampion(veto.champion)
	end)

	Array.forEach(TEAMS, function(teamIndex)
		local teamData = map['team' .. teamIndex]
		teamData.ban = teamData.ban and Array.map(teamData.ban, cleanChampion) or nil
		teamData.pick = teamData.ban and Array.map(teamData.pick, cleanChampion) or nil

		Array.forEach(teamData.players, function(player)
			player.champion = cleanChampion(player.champion)
		end)
	end)
end

---@param model table
---@return Html
function BigMatch.render(model)
	return mw.html.create('div')
		:wikitext(BigMatch.header(model))
		:node(BigMatch.games(model))
		:wikitext(BigMatch.footer(model))
end

---@param model table
---@return string
function BigMatch.header(model)
	return TemplateEngine():render(Template.header, model)
end

---@param model table
---@return Html|string?
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

---@param model table
---@return string
function BigMatch.footer(model)
	return TemplateEngine():render(Template.footer, model)
end

---@return string
---@return string
function BigMatch._getId()
	local title = mw.title.getCurrentTitle().text

	-- Title format is `ID bracketID matchID`
	local titleParts = mw.text.split(title, ' ')

	-- Return bracketID and matchID
	return titleParts[2], titleParts[3]
end

---@param page string?
---@return tournament|{}
function BigMatch._fetchTournamentInfo(page)
	if not page then
		return {}
	end

	return mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'pagename, name, patch',
		conditions = '[[pagename::'.. page .. ']]',
	})[1] or {}
end

---@param identifiers string[]
---@return string?
function BigMatch._fetchTournamentPageFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
		limit = 1,
	})[1] or {}
	return data.parent
end

return BigMatch
