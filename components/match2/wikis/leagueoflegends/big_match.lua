---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:BigMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local HeroIcon = require('Module:ChampionIcon')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')
local Match = require('Module:Match')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine/dev')
local VodLink = require('Module:VodLink')

local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local Template = Lua.import('Module:BigMatch/Template', {requireDevIfEnabled = true})

---@class BigMatch
local BigMatch = Class.new()

mw.ext.LOLDB = {}
function mw.ext.LOLDB.getGame(apiId)
	if not apiId then
		return nil
	end

	return {
	["championVeto"] = {
		{
			["champion"] = "Caitlyn",
			["team"] = 2,
			["type"] = "ban",
			["vetoNumber"] = 1,
		},
		{
			["champion"] = "Varus",
			["team"] = 1,
			["type"] = "ban",
			["vetoNumber"] = 2,
		},
		{
			["champion"] = "Elise",
			["team"] = 2,
			["type"] = "ban",
			["vetoNumber"] = 3,
		},
		{
			["champion"] = "Karma",
			["team"] = 1,
			["type"] = "ban",
			["vetoNumber"] = 4,
		},
		{
			["champion"] = "Sejuani",
			["team"] = 2,
			["type"] = "ban",
			["vetoNumber"] = 5,
		},
		{
			["champion"] = "Ashe",
			["team"] = 1,
			["type"] = "ban",
			["vetoNumber"] = 6,
		},
		{
			["champion"] = "Vi",
			["team"] = 2,
			["type"] = "pick",
			["vetoNumber"] = 7,
		},
		{
			["champion"] = "Veigar",
			["team"] = 1,
			["type"] = "pick",
			["vetoNumber"] = 8,
		},
		{
			["champion"] = "Lee Sin",
			["team"] = 1,
			["type"] = "pick",
			["vetoNumber"] = 9,
		},
		{
			["champion"] = "Ahri",
			["team"] = 2,
			["type"] = "pick",
			["vetoNumber"] = 10,
		},
		{
			["champion"] = "K'Sante",
			["team"] = 2,
			["type"] = "pick",
			["vetoNumber"] = 11,
		},
		{
			["champion"] = "Xayah",
			["team"] = 1,
			["type"] = "pick",
			["vetoNumber"] = 12,
		},
		{
			["champion"] = "Zeri",
			["team"] = 1,
			["type"] = "ban",
			["vetoNumber"] = 13,
		},
		{
			["champion"] = "Rakan",
			["team"] = 2,
			["type"] = "ban",
			["vetoNumber"] = 14,
		},
		{
			["champion"] = "Thresh",
			["team"] = 1,
			["type"] = "ban",
			["vetoNumber"] = 15,
		},
		{
			["champion"] = "Renata Glasc",
			["team"] = 2,
			["type"] = "ban",
			["vetoNumber"] = 16,
		},
		{
			["champion"] = "Renekton",
			["team"] = 1,
			["type"] = "pick",
			["vetoNumber"] = 17,
		},
		{
			["champion"] = "Aphelios",
			["team"] = 2,
			["type"] = "pick",
			["vetoNumber"] = 18,
		},
		{
			["champion"] = "Tahm Kench",
			["team"] = 2,
			["type"] = "pick",
			["vetoNumber"] = 19,
		},
		{
			["champion"] = "Nautilus",
			["team"] = 1,
			["type"] = "pick",
			["vetoNumber"] = 20,
		},
	},
	["length"] = 1414,
	["team1"] = {
		["baronKills"] = 1,
		["color"] = "red",
		["dragonKills"] = 3,
		["inhibitorKills"] = 2,
		["name"] = "Sengoku Gaming",
		["players"] = {
			{
				["assists"] = 5,
				["champion"] = "Renekton",
				["creepScore"] = 208,
				["damageDone"] = 126604,
				["deaths"] = 1,
				["gold"] = 11349,
				["id"] = "Paz",
				["items"] = {
					"Doran's Shield",
					"Goredrinker",
					"Black Cleaver",
					"Plated Steelcaps",
				},
				["kills"] = 6,
				["role"] = "top",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Demolish",
							"Grasp of the Undying",
							"Second Wind",
							"Overgrowth",
						},
						["tree"] = "Resolve",
					},
					["secondary"] = {
						["runes"] = {
							"Manaflow Band",
							"Scorch",
						},
						["tree"] = "Sorcery",
					},
				},
				["spells"] = {
					"Flash",
					"Teleport",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 9,
			},
			{
				["assists"] = 12,
				["champion"] = "Lee Sin",
				["creepScore"] = 155,
				["damageDone"] = 170587,
				["deaths"] = 1,
				["gold"] = 8983,
				["id"] = "Once",
				["items"] = {
					"Goredrinker",
					"Control Ward",
					"Mercury's Treads",
					"Caulfield's Warhammer",
					"Kindlegem",
					"Broken Stopwatch",
				},
				["kills"] = 1,
				["role"] = "jungle",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Conditioning",
							"Font of Life",
							"Aftershock",
							"Overgrowth",
						},
						["tree"] = "Resolve",
					},
					["secondary"] = {
						["runes"] = {
							"Relentless Hunter",
							"Zombie Ward",
						},
						["tree"] = "Domination",
					},
				},
				["spells"] = {
					"Smite",
					"Flash",
				},
				["trinket"] = "Stealth Ward",
				["wardsPlaced"] = 11,
			},
			{
				["assists"] = 11,
				["champion"] = "Xayah",
				["creepScore"] = 233,
				["damageDone"] = 144641,
				["deaths"] = 1,
				["gold"] = 12068,
				["id"] = "LokeN",
				["items"] = {
					"Doran's Blade",
					"Galeforce",
					"Berserker's Greaves",
					"Navori Quickblades",
					"Rapid Firecannon",
					"Vampiric Scepter",
				},
				["kills"] = 4,
				["role"] = "bottom",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Ingenious Hunter",
							"Taste of Blood",
							"Hail of Blades",
							"Zombie Ward",
						},
						["tree"] = "Domination",
					},
					["secondary"] = {
						["runes"] = {
							"Bone Plating",
							"Overgrowth",
						},
						["tree"] = "Resolve",
					},
				},
				["spells"] = {
					"Heal",
					"Flash",
				},
				["trinket"] = "Farsight Alteration",
				["wardsPlaced"] = 10,
			},
			{
				["assists"] = 8,
				["champion"] = "Veigar",
				["creepScore"] = 241,
				["damageDone"] = 154804,
				["deaths"] = 0,
				["gold"] = 11692,
				["id"] = "Jett",
				["items"] = {
					"Ionian Boots of Lucidity",
					"Rod of Ages",
					"Seraph's Embrace",
					"Mejai's Soulstealer",
					"Blighting Jewel",
					"Broken Stopwatch",
				},
				["kills"] = 7,
				["role"] = "middle",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Last Stand",
							"Presence of Mind",
							"Conqueror",
							"Legend: Tenacity",
						},
						["tree"] = "Precision",
					},
					["secondary"] = {
						["runes"] = {
							"Second Wind",
							"Overgrowth",
						},
						["tree"] = "Resolve",
					},
				},
				["spells"] = {
					"Teleport",
					"Flash",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 5,
			},
			{
				["assists"] = 12,
				["champion"] = "Nautilus",
				["creepScore"] = 34,
				["damageDone"] = 17229,
				["deaths"] = 2,
				["gold"] = 6414,
				["id"] = "Enty",
				["items"] = {
					"Mercury's Treads",
					"Bulwark of the Mountain",
					"Locket of the Iron Solari",
					"Ruby Crystal",
				},
				["kills"] = 0,
				["role"] = "support",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Cheap Shot",
							"Ultimate Hunter",
							"Hail of Blades",
							"Zombie Ward",
						},
						["tree"] = "Domination",
					},
					["secondary"] = {
						["runes"] = {
							"Biscuit Delivery",
							"Cosmic Insight",
						},
						["tree"] = "Inspiration",
					},
				},
				["spells"] = {
					"Ignite",
					"Flash",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 49,
			},
		},
		["towerKills"] = 9,
	},
	["team1Score"] = 1,
	["team2"] = {
		["baronKills"] = 0,
		["color"] = "blue",
		["dragonKills"] = 0,
		["inhibitorKills"] = 0,
		["name"] = "V3 Esports",
		["players"] = {
			{
				["assists"] = 2,
				["champion"] = "Tahm Kench",
				["creepScore"] = 44,
				["damageDone"] = 15342,
				["deaths"] = 3,
				["gold"] = 5052,
				["id"] = "hetel",
				["items"] = {
					"Refillable Potion",
					"Mercury's Treads",
					"Bulwark of the Mountain",
					"Control Ward",
					"Locket of the Iron Solari",
				},
				["kills"] = 0,
				["role"] = "support",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Transcendence",
							"Scorch",
							"Manaflow Band",
							"Summon Aery",
						},
						["tree"] = "Sorcery",
					},
					["secondary"] = {
						["runes"] = {
							"Magical Footwear",
							"Future's Market",
						},
						["tree"] = "Inspiration",
					},
				},
				["spells"] = {
					"Ignite",
					"Flash",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 35,
			},
			{
				["assists"] = 1,
				["champion"] = "Vi",
				["creepScore"] = 132,
				["damageDone"] = 139618,
				["deaths"] = 4,
				["gold"] = 7511,
				["id"] = "HRK",
				["items"] = {
					"Divine Sunderer",
					"Plated Steelcaps",
					"Stopwatch",
					"Long Sword",
					"Control Ward",
					"Kindlegem",
				},
				["kills"] = 3,
				["role"] = "jungle",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Lethal Tempo",
							"Legend: Tenacity",
							"Triumph",
							"Coup de Grace",
						},
						["tree"] = "Precision",
					},
					["secondary"] = {
						["runes"] = {
							"Magical Footwear",
							"Cosmic Insight",
						},
						["tree"] = "Inspiration",
					},
				},
				["spells"] = {
					"Flash",
					"Smite",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 8,
			},
			{
				["assists"] = 2,
				["champion"] = "K'Sante",
				["creepScore"] = 165,
				["damageDone"] = 83626,
				["deaths"] = 5,
				["gold"] = 7635,
				["id"] = "Washiday",
				["items"] = {
					"Iceborn Gauntlet",
					"Plated Steelcaps",
					"Bami's Cinder",
					"Control Ward",
					"Chain Vest",
				},
				["kills"] = 1,
				["role"] = "top",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Grasp of the Undying",
							"Second Wind",
							"Unflinching",
							"Demolish",
						},
						["tree"] = "Resolve",
					},
					["secondary"] = {
						["runes"] = {
							"Biscuit Delivery",
							"Cosmic Insight",
						},
						["tree"] = "Inspiration",
					},
				},
				["spells"] = {
					"Flash",
					"Teleport",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 10,
			},
			{
				["assists"] = 2,
				["champion"] = "Aphelios",
				["creepScore"] = 209,
				["damageDone"] = 94416,
				["deaths"] = 5,
				["gold"] = 7583,
				["id"] = "dresscode",
				["items"] = {
					"Bloodthirster",
					"Berserker's Greaves",
					"Noonquiver",
					"Control Ward",
					"Pickaxe",
				},
				["kills"] = 0,
				["role"] = "bottom",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Magical Footwear",
							"Biscuit Delivery",
							"First Strike",
							"Cosmic Insight",
						},
						["tree"] = "Inspiration",
					},
					["secondary"] = {
						["runes"] = {
							"Manaflow Band",
							"Scorch",
						},
						["tree"] = "Sorcery",
					},
				},
				["spells"] = {
					"Flash",
					"Heal",
				},
				["trinket"] = "Farsight Alteration",
				["wardsPlaced"] = 9,
			},
			{
				["assists"] = 3,
				["champion"] = "Ahri",
				["creepScore"] = 203,
				["damageDone"] = 108743,
				["deaths"] = 1,
				["gold"] = 7806,
				["id"] = "Ace",
				["items"] = {
					"Doran's Ring",
					"Everfrost",
					"Broken Stopwatch",
					"Ionian Boots of Lucidity",
					"Horizon Focus",
				},
				["kills"] = 1,
				["role"] = "middle",
				["runeData"] = {
					["primary"] = {
						["runes"] = {
							"Cut Down",
							"Presence of Mind",
							"Conqueror",
							"Legend: Alacrity",
						},
						["tree"] = "Precision",
					},
					["secondary"] = {
						["runes"] = {
							"Manaflow Band",
							"Scorch",
						},
						["tree"] = "Sorcery",
					},
				},
				["spells"] = {
					"Flash",
					"Teleport",
				},
				["trinket"] = "Oracle Lens",
				["wardsPlaced"] = 4,
			},
		},
		["towerKills"] = 0,
	},
	["team2Score"] = 0,
	["winner"] = 1,
}
end

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

	---@type BigMatch
	local bigMatch = BigMatch()

	args = bigMatch:_contextualEnrichment(args)

	local match = bigMatch:_match2Director(args)

	local renderModel = match

	renderModel.isBestOfOne = #renderModel.match2games == 1
	renderModel.dateCountdown = tostring(DisplayHelper.MatchCountdownBlock(match))
	renderModel.links = Array.extractValues(Table.map(renderModel.links, function (site, link)
		return site, Table.mergeInto({link = link}, MatchLinks[site])
	end))
	renderModel.match2opponents = Array.map(renderModel.match2opponents, function (opponent, index)
		opponent.opponentIndex = index
		opponent.iconDisplay = mw.ext.TeamTemplate.teamicon(opponent.template)
		opponent.shortname = mw.ext.TeamTemplate.raw(opponent.template).shortname
		opponent.page = mw.ext.TeamTemplate.raw(opponent.template).page
		opponent.name = mw.ext.TeamTemplate.raw(opponent.template).name
		return opponent
	end)
	Array.forEach(renderModel.match2games, function (game, index)
		game.apiInfo = match['map' .. index]

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
		_, game.apiInfo.championVetoByTeam = Array.groupBy(game.apiInfo.championVeto, Operator.item('team'))

		Array.forEach(game.apiInfo.championVetoByTeam, function (team)
			local lastType = 'ban'
			Array.forEach(team, function(veto)
				veto.isBan = veto.type == 'ban'
				veto.isNewGroup = lastType ~= veto.type
				lastType = veto.type
			end)
		end)
	end)

	renderModel.vods = {
		icons = Array.map(renderModel.match2games, function(game, gameIdx)
			return VodLink.display{
				gamenum = gameIdx,
				vod = game.vod,
			}
		end)
	}

	renderModel.generateSeriesDots = function(self)
		return table.concat(Array.map(renderModel.match2games, function (game)
			return game.apiInfo['team' .. self.opponentIndex].scoreDisplay
		end), ' ')
	end
	renderModel.heroIcon = function(self)
		local champion = type(self) == 'table' and self.champion or self
		return HeroIcon._getImage{champion, '48px', date = renderModel.date}
	end

	return bigMatch:render(renderModel)
end

function BigMatch._sumItem(tbl, item)
	return Array.reduce(Array.map(tbl, Operator.item(item)), Operator.add)
end

function BigMatch._abbreviateNumber(number)
	return string.format('%.1fK', number / 1000)
end

function BigMatch:_contextualEnrichment(args)
	-- Retrieve tournament info from the bracket/matchlist
	if String.isEmpty(args.tournamentlink) then
		args.tournamentlink = self:_fetchTournamentPageFromMatch{self:_getId()}
	end

	local tournamentData = self:_fetchTournamentInfo(args.tournamentlink)

	args.patch = args.patch or tournamentData.patch
	args.tournament = {
		name = args.tournament or tournamentData.name,
		link = args.tournamentlink or tournamentData.pagename,
	}

	return args
end

function BigMatch:_match2Director(args)
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
		local map = mw.ext.LOLDB.getGame(args['map' .. gameIndex])
		if not map then
			return
		end

		-- Convert seconds to minutes and seconds
		map.length = math.floor(map.length / 60) .. ':' .. (map.length % 60)

		Array.forEach(TEAMS, function(teamIdx)
			local team = map['team' .. teamIdx]

			map['team' .. teamIdx .. 'side'] = team.color

			-- Sort players based on role
			Array.sortInPlaceBy(team.players, function (player)
				return ROLE_ORDER[player.role]
			end)
		end)

		-- Break down the picks and bans into per team, per type, in order.
		Array.sortInPlaceBy(map.championVeto, Operator.item('vetoNumber'))

		local _, vetoesByTeam = Array.groupBy(map.championVeto, Operator.item('team'))

		Table.mergeInto(map, prefixWithKey(Array.map(vetoesByTeam, function (team)
			return Table.mapValues(Table.groupBy(team, function(_, veto)
				return veto.type
			end), function (vetoType)
				return Array.extractValues(Table.mapValues(vetoType, Operator.item('champion')))
			end)
		end), 't'))


		return map
	end)

	Table.mergeInto(matchData, prefixWithKey(maps, 'map'))
	local match2input = Table.merge(args, Table.deepCopy(matchData))

	local match = CustomMatchGroupInput.processMatch(match2input, {isStandalone = true})

	local bracketId, matchId = self:_getId()
	match.bracketid, match.matchid = 'MATCH_' .. bracketId, matchId

	-- Don't store match1 as BigMatch records are not complete
	Match.store(match, {storeMatch1 = false, storeSmw = false})

	return Table.merge(matchData, match)
end

function BigMatch:render(model)
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')
	overall :wikitext(self:header(model))
			:wikitext(self:games(model))
			:wikitext(self:footer(model))

	return overall
end

function BigMatch:header(model)
	return TemplateEngine():render(Template.header, model)
end

function BigMatch:games(model)
	local games = Array.map(Array.filter(model.match2games, function (game)
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

function BigMatch:footer(model)
	return TemplateEngine():render(Template.footer, model)
end

function BigMatch:_getId()
	local title = mw.title.getCurrentTitle().text

	-- Title format is `ID bracketID matchID`
	local titleParts = mw.text.split(title, ' ')

	return titleParts[2], titleParts[3]
end

function BigMatch:_fetchTournamentInfo(page)
	if not page then
		return {}
	end

	return mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'pagename, name, patch',
		conditions = '[[pagename::'.. page .. ']]',
	})[1] or {}
end

function BigMatch:_fetchTournamentPageFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
		limit = 1,
	})[1] or {}
	return data.parent
end

return BigMatch
