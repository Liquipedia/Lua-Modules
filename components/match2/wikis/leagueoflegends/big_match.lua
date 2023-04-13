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
local Logic = require('Module:Logic')
local Match = require('Module:Match')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine')

local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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
				["runes"] = {
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

function BigMatch.templateHeader()
	return
[=[
<div class="fb-match-page-header">
	<div class="fb-match-page-header-teams" style="display:flex;">
		<div class="fb-match-page-header-team">{{&match2opponents.1.iconDisplay}}<br>[[{{match2opponents.1.name}}]]</div>
		<div class="fb-match-page-header-score">{{match2opponents.1.score}}&ndash;{{match2opponents.2.score}}</div>
		<div class="fb-match-page-header-team">{{&match2opponents.2.iconDisplay}}<br>[[{{match2opponents.2.name}}]]</div>
	</div>
	<div class="fb-match-page-header-tournament">[[{{tournament.link}}|{{tournament.name}}]]</div>
	<div class="fb-match-page-header-tournament">{{&dateCountdown}}</div>
	<div class="fb-match-page-header-tournament">MVP: {{mvp}}</div>
</div>
]=]
end

function BigMatch.templateGame()
	return
[=[
<div class="fb-match-page-header">
	<div class="fb-match-page-header-teams" style="display:flex;">
		<div class="fb-match-page-header-team">{{&match2opponents.1.iconDisplay}}</div>
		<div class="fb-match-page-header-score">{{team1scoreDisplay}}&ndash;{{team2scoreDisplay}}<br>{{length}}</div>
		<div class="fb-match-page-header-team">{{&match2opponents.2.iconDisplay}}</div>
	</div>
	<div class="">MVP: {{mvp}}</div>
</div>
<h3>Picks and Bans</h3>
<div class="fb-match-page-header">
	<div class="fb-match-page-header-teams" style="display:flex;">
		<div class="fb-match-page-header-team">{{&match2opponents.1.iconDisplay}}</div>
		<div class="fb-match-page-header-team">{{&match2opponents.2.iconDisplay}}</div>
	</div>
	<div class="fb-match-page-header-teams" style="display:flex;">
		<div class="fb-match-page-header-team">{{#apiInfo.t1.pick}}{{.}}{{/apiInfo.t1.pick}}{{#apiInfo.t1.ban}}{{.}}{{/apiInfo.t1.ban}}</div>
		<div class="fb-match-page-header-team">{{#apiInfo.t2.pick}}{{.}}{{/apiInfo.t2.pick}}{{#apiInfo.t2.ban}}{{.}}{{/apiInfo.t2.ban}}</div>
	</div>
	<!-- TODO: toogle -->
	<!-- TODO: Pick and Ban Order -->
</div>
<h3>Head-to-Head</h3>
<div class="fb-match-page-header">
	<div class="fb-match-page-header-teams" style="display:flex;">
		<div class="fb-match-page-header-team">{{&match2opponents.1.iconDisplay}}</div>
		<div></div>
		<div class="fb-match-page-header-team">{{&match2opponents.2.iconDisplay}}</div>
	</div>
	<div class="fb-match-page-header-teams" style="display:flex;">
		<div class="fb-match-page-header-team">{{kda}}</div>
		<div class="fb-match-page-header-score">KDA-LOGO<br>KDA</div>
		<div class="fb-match-page-header-team">{{kda}}</div>
	</div>
	<!-- TODO Rest of the stuff -->
</div>
<h3>Player Performance</h3>
<div class="fb-match-page-header">
	<!-- TODO Player Cards -->
</div>
]=]
end

function BigMatch.templateFooter()
	return
[=[
<h3>Additional Information</h3>
<div>
{{#links}}
	[[File:{{icon}}|link={{link}}|15px|{{text}}]]
{{/links}}
</div>
{{#patch}}
<br>
<div>
	[[Patch {{patch}}|{{patch}}]]
</div>
{{/patch}}
]=]
end

local LINK_DATA = {
	vod = {icon = 'VOD Icon.png', text = 'Watch VOD'},
	preview = {icon = 'Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'LiveReport32.png', text = 'Live Report Thread'},
	recap = {icon = 'Reviews32.png', text = 'Recap'},
	reddit = {icon = 'Reddit-icon.png', text = 'Head-to-head statistics'},
	gol = {icon = 'Gol.gg_allmode.png', text = 'GolGG Match Report'},
	factor = {icon = 'Factor.gg lightmode.png', text = 'FactorGG Match Report'},
}

function BigMatch.run(frame)
	local args = Arguments.getArgs(frame)

	---@type BigMatch
	local bigMatch = BigMatch()

	args = bigMatch:_contextualEnrichment(args)

	local match = bigMatch:_match2Director(args)

	local renderModel = match
	renderModel.links = Array.extractValues(Table.map(renderModel.links, function (site, link)
		return site, Table.mergeInto({link = link}, LINK_DATA[site])
	end))
	renderModel.match2opponents = Array.map(renderModel.match2opponents, function (opponent)
		opponent.iconDisplay = mw.ext.TeamTemplate.teamicon(opponent.template)
		return opponent
	end)
	Array.forEach(renderModel.match2games, function (game, index)
		game.apiInfo = match['map' .. index]
	end)

	return bigMatch:render(renderModel)
end

function BigMatch:_contextualEnrichment(args)
	-- Retrieve tournament link from the bracket
	if String.isEmpty(args.tournamentlink) then
		args.tournamentlink = self:_fetchTournamentLinkFromMatch{self:_getId()}
	end

	local tournamentData = self:_fetchTournamentInfo(args.tournamentlink)

	args.patch = args.patch or tournamentData.patch
	args.tournament = {
		name = args.tournament or tournamentData.name,
		link = args.tournamentlink or tournamentData.pagename,
	}

	return args
end

-- TODO: WIP
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

	local games = Array.mapIndexes(function(gameIndex)
		local game = mw.ext.LOLDB.getGame(args['map' .. gameIndex])
		if not game then
			return
		end

		game.length = math.floor(game.length/60) .. ':' .. (game.length%60)
		game.team1side = game.team1.color
		game.team2side = game.team2.color

		Array.sortInPlaceBy(game.championVeto, function(veto) return veto.vetoNumber end)

		local _, vetoesByTeam = Array.groupBy(game.championVeto, function (veto)
			return veto.team
		end)

		Table.mergeInto(game, prefixWithKey(Array.map(vetoesByTeam, function (team)
			return Table.mapValues(Table.groupBy(team, function(_, veto)
				return veto.type
			end), function (vetoType)
				return Array.extractValues(Table.mapValues(vetoType, function(veto)
					return veto.champion
				end))
			end)
		end), 't'))

		return game
	end)
	Table.mergeInto(matchData, Table.map(games, function(index, game) return 'map' .. index, game end))
	local match2input = Table.merge(args, Table.deepCopy(matchData))
	mw.logObject(match2input, 'Sent toi match2')
	local match = CustomMatchGroupInput.processMatch(match2input, {isStandalone = true})

	local bracketId, matchId = self:_getId()
	match.bracketid, match.matchid = 'MATCH_' .. bracketId, matchId

	-- Don't store match1 as BigMatch records are not complete
	Match.store(match, {storeMatch1 = false, storeSmw = false})

	mw.logObject(match, 'Stored Match')

	return Table.merge(match, matchData)
end

function BigMatch:render(model)
	mw.logObject(model, 'Rendering on')
	local overall = mw.html.create('div'):addClass('fb-match-page-overall')
	overall :wikitext(self:header(model))
			:wikitext(self:games(model))
			:wikitext(self:footer(model))

	return overall
end

function BigMatch:header(model)
	return TemplateEngine():render(BigMatch.templateHeader(), model)
end

function BigMatch:games(model)
	local games = Array.map(Array.filter(model.match2games, function (game)
		return game.resulttype ~= 'np'
	end), function (game)
		mw.logObject(Table.merge(model, game), 'Game Model')
		return TemplateEngine():render(BigMatch.templateGame(), Table.merge(model, game))
	end)

	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	Array.forEach(games, function (game, idx)
		tabs['name' .. idx] = 'Map ' .. idx
		tabs['content' .. idx] = tostring(game)
	end)

	return Tabs.dynamic(tabs)
end

function BigMatch:footer(model)
	return TemplateEngine():render(BigMatch.templateFooter(), model)
end

function BigMatch:_getId()
	local title = mw.title.getCurrentTitle().text

	-- Match alphanumeric pattern 10 characters long, followed by space and then the match id
	local staticId = string.match(title, '%w%w%w%w%w%w%w%w%w%w .*')
	local fullBracketId = string.match(title, '%w%w%w%w%w%w%w%w%w%w')
	local matchId = string.sub(staticId, 12)

	return fullBracketId, matchId
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

function BigMatch:_fetchTournamentLinkFromMatch(identifiers)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		query = 'parent, pagename',
		conditions = '[[match2id::'.. table.concat(identifiers, '_') .. ']]',
	})[1] or {}
	return Logic.emptyOr(data.parent, data.pagename)
end

return BigMatch
