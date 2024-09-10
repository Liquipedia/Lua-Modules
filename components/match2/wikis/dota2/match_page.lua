---
-- @Liquipedia
-- wiki=dota2
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
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TemplateEngine = require('Module:TemplateEngine')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local Display = Lua.import('Module:MatchPage/Template')

local MatchPage = {}

local NO_CHARACTER = 'default'
local NOT_PLAYED = 'np'

local AVAILABLE_FOR_TIERS = {1}
local MATCH_PAGE_START_TIME = 1725148800 -- September 1st 2024 midnight

---@param match table
---@return boolean
function MatchPage.isEnabledFor(match)
	return Table.includes(AVAILABLE_FOR_TIERS, tonumber(match.liquipediatier))
			and (match.timestamp == DateExt.defaultTimestamp or match.timestamp > MATCH_PAGE_START_TIME)
end

---@class Dota2MatchPageViewModelGame: MatchGroupUtilGame
---@field finished boolean
---@field winnerName string?
---@field teams table[]

---@class Dota2MatchPageViewModelOpponent: standardOpponent
---@field opponentIndex integer
---@field iconDisplay string
---@field shortname string
---@field page string
---@field seriesDots string[]

---@param props {match: MatchGroupUtilMatch}
---@return Html
function MatchPage.getByMatchId(props)
	---@class Dota2MatchPageViewModel: MatchGroupUtilMatch
	---@field games Dota2MatchPageViewModelGame[]
	---@field opponents Dota2MatchPageViewModelOpponent[]
	local viewModel = props.match

	viewModel.isBestOfOne = #viewModel.games == 1
	viewModel.dateCountdown = viewModel.timestamp ~= DateExt.defaultTimestamp and
		DisplayHelper.MatchCountdownBlock(viewModel) or nil

	local phase = MatchGroupUtil.computeMatchPhase(props.match)
	viewModel.statusText = phase == 'ongoing' and 'live' or phase

	local function makeItemDisplay(item)
		if String.isEmpty(item.name) then
			return '[[File:EmptyIcon itemicon dota2 gameasset.png|64px|Empty|link=]]'
		end
		return '[[File:'.. item.image ..'|64px|'.. item.name ..'|link=]]'
	end

	-- Update the view model with game and team data
	Array.forEach(viewModel.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(Array.range(1, 2), function(teamIdx)
			local team = {players = {}}

			team.scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-'
			team.side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side'])

			for _, player in Table.iter.pairsByPrefix(game.participants, teamIdx .. '_') do
				local newPlayer = Table.mergeInto(player, {
					displayName = player.name or player.player,
					link = player.player,
					items = Array.map(player.items or {}, makeItemDisplay),
					backpackitems = Array.map(player.backpackitems or {}, makeItemDisplay),
					neutralitem = makeItemDisplay(player.neutralitem or {}),
				})

				newPlayer.displayDamageDone = MatchPage._abbreviateNumber(player.damagedone)
				newPlayer.displayGold = MatchPage._abbreviateNumber(player.gold)

				table.insert(team.players, newPlayer)
			end

			if game.finished then
				-- Aggregate stats
				team.gold = MatchPage._abbreviateNumber(MatchPage._sumItem(team.players, 'gold'))
				team.kills = MatchPage._sumItem(team.players, 'kills')
				team.deaths = MatchPage._sumItem(team.players, 'deaths')
				team.assists = MatchPage._sumItem(team.players, 'assists')

				-- Set fields
				team.objectives = game.extradata['team' .. teamIdx .. 'objectives']
			end

			team.picks = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'pick' and veto.team == teamIdx
			end)
			team.bans = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'ban' and veto.team == teamIdx
			end)

			return team
		end)
		if game.finished and viewModel.opponents[game.winner] then
			game.winnerName = viewModel.opponents[game.winner].name
		end
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

	viewModel.vods = Array.map(viewModel.games, function(game, gameIdx)
		return game.vod and VodLink.display{
			gamenum = gameIdx,
			vod = game.vod,
		} or ''
	end)

	-- Create an object array for links
	local function processLink(site, link)
		return Table.mergeInto({link = link}, MatchLinks[site])
	end

	viewModel.links = Array.flatMap(Table.entries(viewModel.links), function(linkData)
		local site, link = unpack(linkData)
		if type(link) == 'table' then
			return Array.map(link, function(sublink)
				return processLink(site, sublink)
			end)
		end
		return {processLink(site, link)}
	end)

	viewModel.heroIcon = function(c)
		local character = c
		if type(c) == 'table' then
			character = c.character
			---@cast character -table
		end
		return CharacterIcon.Icon{
			character = character or NO_CHARACTER,
			date = viewModel.date
		}
	end

	local displayTitle = MatchPage.makeDisplayTitle(viewModel)
	mw.getCurrentFrame():preprocess(table.concat{'{{DISPLAYTITLE:', displayTitle, '}}'})

	return MatchPage.render(viewModel)
end

---@param viewModel table
---@return string
function MatchPage.makeDisplayTitle(viewModel)
	if not viewModel.opponents[1].shortname and viewModel.opponents[2].shortname then
		return table.concat({'Match in', viewModel.tickername}, ' ')
	end

	local team1name = viewModel.opponents[1].shortname or 'TBD'
	local team2name = viewModel.opponents[2].shortname or 'TBD'
	local tournamentName = viewModel.tickername
	local displayTitle = team1name .. ' vs. ' .. team2name
	if not tournamentName then
		return displayTitle
	end

	return displayTitle .. ' @ ' .. tournamentName
end

---@param tbl table
---@param item string
---@return number
function MatchPage._sumItem(tbl, item)
	return Array.reduce(Array.map(tbl, Operator.property(item)), Operator.add, 0)
end

---@param number number?
---@return string?
function MatchPage._abbreviateNumber(number)
	if not number then
		return
	end
	return string.format('%.1fK', number / 1000)
end

---@param model table
---@return Html
function MatchPage.render(model)
	return mw.html.create('div')
		:wikitext(MatchPage.header(model))
		:node(MatchPage.games(model))
		:wikitext(MatchPage.footer(model))
end

---@param model table
---@return string
function MatchPage.header(model)
	return TemplateEngine():render(Display.header, model)
end

---@param model table
---@return string
function MatchPage.games(model)
	local games = Array.map(Array.filter(model.games, function(game)
		return game.resultType ~= NOT_PLAYED
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
function MatchPage.footer(model)
	return TemplateEngine():render(Display.footer, model)
end

return MatchPage
