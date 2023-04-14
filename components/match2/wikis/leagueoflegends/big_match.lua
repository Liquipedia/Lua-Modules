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
local Math = require('Module:MathUtil')
local Match = require('Module:Match')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine/dev')

local CustomMatchGroupInput = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})

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
<div class="match-bm-lol-h2h">
	<div class="match-bm-lol-h2h-header">
		<div class="match-bm-lol-h2h-header-team">{{&match2opponents.1.iconDisplay}}</div>
		<div class="match-bm-lol-h2h-stat-title"></div>
		<div class="match-bm-lol-h2h-header-team">{{&match2opponents.2.iconDisplay}}</div>
	</div>
	<div class="match-bm-lol-h2h-section">
		<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.kills}}/{{apiInfo.team1.deaths}}/{{apiInfo.team1.assists}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon kda.png|link=]]<br>KDA</div>
			<div>{{apiInfo.team2.kills}}/{{apiInfo.team2.deaths}}/{{apiInfo.team2.assists}}</div>
		</div>
		<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.gold}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon gold.png|link=]]<br>Gold</div>
			<div>{{apiInfo.team2.gold}}</div>
		</div>
	</div>
	<div class="match-bm-lol-h2h-section">
	<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.towerKills}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon tower.png|link=]]<br>Towers</div>
			<div>{{apiInfo.team2.towerKills}}</div>
		</div>
		<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.inhibitorKills}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon inhibitor.png|link=]]<br>Inhibitors</div>
			<div>{{apiInfo.team2.inhibitorKills}}</div>
		</div>
		<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.baronKills}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon baron.png|link=]]<br>Barons</div>
			<div>{{apiInfo.team2.baronKills}}</div>
		</div>
		<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.dragonKills}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon dragon.png|link=]]<br>Drakes</div>
			<div>{{apiInfo.team2.dragonKills}}</div>
		</div>
		<!--<div class="match-bm-lol-h2h-stat">
			<div>{{apiInfo.team1.heraldKills}}</div>
			<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon herald.png|link=]]<br>Heralds</div>
			<div>{{apiInfo.team2.heraldKills}}</div>
		</div>-->
	</div>
</div>
<h3>Player Performance</h3>
<div class="match-bm-lol-players-wrapper">
	<div class="match-bm-lol-players-team"><div class="match-bm-lol-players-team-header">{{&match2opponents.1.iconDisplay}}</div>
		{{#apiInfo.team1.players}}
			<div class="match-bm-lol-players-player">
				<div class="match-bm-lol-players-player-details">
					<div class="match-bm-lol-players-player-character">
						<div class="match-bm-lol-players-player-avatar"><div class="match-bm-lol-players-player-icon">{{&championDisplay}}</div><div class="match-bm-lol-players-player-role">[[File:Lol role {{roleIcon}}.png|link=]]</div></div>
						<div class="match-bm-lol-players-player-name">[[{{id}}]]<i>{{champion}}</i></div>
					</div>
					<div class="match-bm-lol-players-player-loadout">
						<!-- Loadout -->
						<div class="match-bm-lol-players-player-loadout-rs-wrap">
							<!-- Runes/Spells -->
							<div class="match-bm-lol-players-player-loadout-rs">[[File:Rune {{runeKeystone}}.png|24px]][[File:Rune {{runeSecondaryTree}}.png|24px]]</div>
							<div class="match-bm-lol-players-player-loadout-rs">[[File:Summoner spell {{spells.1}}.png|24px]][[File:Summoner spell {{spells.2}}.png|24px]]</div>
						</div>
						<div class="match-bm-lol-players-player-loadout-items">
							<!-- Items -->
							<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
							<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
						</div>
					</div>
				</div>
				<div class="match-bm-lol-players-player-stats">
					<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=]] {{kills}}/{{deaths}}/{{assists}}</div>
					<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=]] {{creepScore}}</div>
					<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=]] {{damageDone}}</div>
				</div>
			</div>
		{{/apiInfo.team1.players}}
	</div>
	<div class="match-bm-lol-players-team"><div class="match-bm-lol-players-team-header">{{&match2opponents.2.iconDisplay}}</div>
		{{#apiInfo.team2.players}}
			<div class="match-bm-lol-players-player">
				<div class="match-bm-lol-players-player-details">
					<div class="match-bm-lol-players-player-character">
						<div class="match-bm-lol-players-player-avatar"><div class="match-bm-lol-players-player-icon">{{&championDisplay}}</div><div class="match-bm-lol-players-player-role">[[File:Lol role {{roleIcon}}.png|link=]]</div></div>
						<div class="match-bm-lol-players-player-name">[[{{id}}]]<i>{{champion}}</i></div>
					</div>
					<div class="match-bm-lol-players-player-loadout">
						<!-- Loadout -->
						<div class="match-bm-lol-players-player-loadout-rs-wrap">
							<!-- Runes/Spells -->
							<div class="match-bm-lol-players-player-loadout-rs">[[File:Rune {{runeKeystone}}.png|24px]][[File:Rune {{runeSecondaryTree}}.png|24px]]</div>
							<div class="match-bm-lol-players-player-loadout-rs">[[File:Summoner spell {{spells.1}}.png|24px]][[File:Summoner spell {{spells.2}}.png|24px]]</div>
						</div>
						<div class="match-bm-lol-players-player-loadout-items">
							<!-- Items -->
							<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
							<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
						</div>
					</div>
				</div>
				<div class="match-bm-lol-players-player-stats">
					<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=]] {{kills}}/{{deaths}}/{{assists}}</div>
					<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=]] {{creepScore}}</div>
					<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=]] {{damageDone}}</div>
				</div>
			</div>
		{{/apiInfo.team2.players}}
	</div>
</div>
]=]
end

function BigMatch.templateFooter()
	return
[=[
<h3>Additional Information</h3>
<div class="fb-match-page-header-tournament" style="gap:4px;">{{#links}}[[File:{{icon}}|link={{link}}|15px|{{text}}]]{{/links}}</div>
{{#patch}}
<br><div class="fb-match-page-header-tournament" style="gap:4px;">[[Patch {{patch}}]]</div>
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

local KEYSTONES = {
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
}

local ROLE_ORDER = Table.map({
	'top',
	'jungle',
	'middle',
	'bottom',
	'support',
}, function (key, value)
	return value, key
end)

local DEFAULT_ITEM = 'EmptyIcon'

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

		Array.forEach({'team1', 'team2'}, function(teamIdx)
			local team = game.apiInfo[teamIdx]
			Array.forEach(team.players, function(player)
				player.championDisplay = HeroIcon._getImage{player.champion, '48px', date = renderModel.date}
				player.roleIcon = player.role .. ' ' .. team.color
				player.runeKeystone = Array.filter(player.runeData.primary.runes, function(rune)
					return Table.includes(KEYSTONES, rune)
				end)[1]
				player.runeSecondaryTree = player.runeData.secondary.tree
				player.items = Array.map(Array.range(1, 6), function (idx)
					return player.items[idx] or DEFAULT_ITEM
				end)
				player.damageDone = string.format('%.1fK', player.damageDone / 1000)
			end)
		end)
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
		Array.forEach({'team1', 'team2'}, function(teamIdx)
			local team = game[teamIdx]

			game[teamIdx .. 'side'] = team.color
			-- Sort players based on role
			Array.sortInPlaceBy(team.players, function (player)
				return ROLE_ORDER[player.role]
			end)

			-- Aggregate stats
			team.gold = string.format('%.1fK', Math.sum(Array.map(team.players, function (player) return player.gold end)) / 1000)
			team.kills = Math.sum(Array.map(team.players, function (player) return player.kills end))
			team.deaths = Math.sum(Array.map(team.players, function (player) return player.deaths end))
			team.assists = Math.sum(Array.map(team.players, function (player) return player.assists end))
		end)

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

	return Table.merge(matchData, match)
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
