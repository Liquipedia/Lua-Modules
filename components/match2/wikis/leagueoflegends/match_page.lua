---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local MatchLinks = mw.loadData('Module:MatchLinks')
local Operator = require('Module:Operator')
local String = require('Module:String')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Display = Lua.import('Module:MatchPage/Template')

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
}, function(_, value)
	return value, true
end)

local NO_CHARACTER = 'default'
local NOT_PLAYED = 'np'
local DEFAULT_ITEM = 'EmptyIcon'
local TEAMS = Array.range(1, 2)
local AVAILABLE_FOR_TIERS = {1, 2, 3}
local ITEMS_TO_SHOW = 6

local BIG_MATCH_START_TIME = 1619827201 -- May 1st 2021 midnight

---@param match table
---@return boolean
function BigMatch.isEnabledFor(match)
	return Table.includes(AVAILABLE_FOR_TIERS, tonumber(match.liquipediatier))
			and (match.timestamp == DateExt.defaultTimestamp or match.timestamp > BIG_MATCH_START_TIME)
end

---@param props table
---@return Html
function BigMatch.getByMatchId(props)
	local viewModel = props.match
	mw.logObject(viewModel, 'VM')

	viewModel.isBestOfOne = #viewModel.games == 1
	viewModel.dateCountdown = viewModel.timestamp ~= DateExt.defaultTimestamp and
		DisplayHelper.MatchCountdownBlock(viewModel) or nil

	-- Create an object array for links
	viewModel.links = Array.extractValues(Table.map(viewModel.links, function(site, link)
		return site, Table.mergeInto({link = link}, MatchLinks[site])
	end))

	-- Update the view model with game and team data
	Array.forEach(viewModel.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(TEAMS, function(teamIdx)
			local team = {players = {}}

			team.scoreDisplay = game.winner == teamIdx and 'W' or game.finished and 'L' or '-'
			team.side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side'])

			for _, player in Table.iter.pairsByPrefix(game.participants, teamIdx .. '_') do
				table.insert(team.players, Table.mergeInto(player, {
					roleIcon = player.role .. ' ' .. team.side,
					items = Array.map(Array.range(1, ITEMS_TO_SHOW), function(idx)
						return player.items[idx] or DEFAULT_ITEM
					end),
					runeKeystone = Array.filter(player.runes.primary.runes, function(rune)
						return KEYSTONES[rune]
					end)[1]
				}))
			end

			-- Aggregate stats
			team.gold = BigMatch._abbreviateNumber(BigMatch._sumItem(team.players, 'gold'))
			team.kills = BigMatch._sumItem(team.players, 'kills')
			team.deaths = BigMatch._sumItem(team.players, 'deaths')
			team.assists = BigMatch._sumItem(team.players, 'assists')

			team.picks = Array.map(team.players, Operator.property('character'))

			team.bans = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'ban' and veto.team == teamIdx
			end)

			return team
		end)

		local _
		_, game.championVetoByTeam = Array.groupBy(game.extradata.vetophase or {}, Operator.property('team'))

		Array.forEach(game.championVetoByTeam, function(team)
			local lastType = 'ban'
			Array.forEach(team, function(veto)
				veto.isBan = veto.type == 'ban'
				veto.isNewGroup = lastType ~= veto.type
				lastType = veto.type
			end)
		end)
	end)

	-- Add more opponent data field
	Array.forEach(viewModel.opponents, function(opponent, index)
		opponent.opponentIndex = index

		if not opponent.template or not mw.ext.TeamTemplate.teamexists(opponent.template) then
			return
		end
		local teamTemplate = mw.ext.TeamTemplate.raw(opponent.template)

		opponent.iconDisplay = mw.ext.TeamTemplate.teamicon(opponent.template)
		opponent.shortname = teamTemplate.shortname
		opponent.page = teamTemplate.page
		opponent.name = teamTemplate.name

		opponent.seriesDots = Array.map(viewModel.games, function(game)
			return game.teams[index].scoreDisplay
		end)
	end)

	viewModel.vods = {
		icons = Array.map(viewModel.games, function(game, gameIdx)
			return game.vod and VodLink.display{
				gamenum = gameIdx,
				vod = game.vod,
			} or ''
		end)
	}

	viewModel.heroIcon = function(self)
		local champion = self
		if type(self) == 'table' then
			champion = self.champion or self.character
			---@cast champion -table
		end
		return CharacterIcon.Icon{
			character = champion or NO_CHARACTER,
			date = viewModel.date
		}
	end

	return BigMatch.render(viewModel)
end

---@param tbl table
---@param item string
---@return number
function BigMatch._sumItem(tbl, item)
	return Array.reduce(Array.map(tbl, Operator.property(item)), Operator.add, 0)
end

---@param number number
---@return string
function BigMatch._abbreviateNumber(number)
	return string.format('%.1fK', number / 1000)
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
	return TemplateEngine():render(Display.header, model)
end

---@param model table
---@return string
function BigMatch.games(model)
	local games = Array.map(Array.filter(model.games, function(game)
		return game.resulttype ~= NOT_PLAYED
	end), function(game)
		return TemplateEngine():render(Display.game, Table.merge(model, game))
	end)

	if #games < 2 then
		return tostring(games[1])
	end

	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	Array.forEach(games, function(game, idx)
		tabs['name' .. idx] = 'Game ' .. idx
		tabs['content' .. idx] = tostring(game)
	end)

	return tostring(Tabs.dynamic(tabs))
end

---@param model table
---@return string
function BigMatch.footer(model)
	return TemplateEngine():render(Display.footer, model)
end

return BigMatch
