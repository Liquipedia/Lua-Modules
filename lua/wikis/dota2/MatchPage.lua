---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table') ---@module 'commons.Table'
local TemplateEngine = require('Module:TemplateEngine')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local Display = Lua.import('Module:MatchPage/Template')

local Link = Lua.import('Module:Widget/Basic/Link')

---@class Dota2MatchPage: BaseMatchPage
local MatchPage = Class.new(BaseMatchPage)

local NO_CHARACTER = 'default'

local AVAILABLE_FOR_TIERS = {1}
local MATCH_PAGE_START_TIME = 1725148800 -- September 1st 2024 midnight

---@param match table
---@return boolean
function MatchPage.isEnabledFor(match)
	return Table.includes(AVAILABLE_FOR_TIERS, tonumber(match.liquipediatier))
			and (match.timestamp == DateExt.defaultTimestamp or match.timestamp > MATCH_PAGE_START_TIME)
end

---@param props {match: MatchGroupUtilMatch}
---@return Widget
function MatchPage.getByMatchId(props)
	local matchPage = MatchPage(props.match)

	-- Update the view model with game and team data
	matchPage:populateGames()

	-- Add more opponent data field
	matchPage:populateOpponents()

	return matchPage:render()
end

function MatchPage:populateGames()
	Array.forEach(self.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(Array.range(1, 2), function(teamIdx)
			local team = {}

			team.scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-'
			team.side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side'])
			team.players = Array.map(game.opponents[teamIdx].players or {}, function(player)
				local newPlayer = Table.mergeInto(player, {
					displayName = player.name or player.player,
					link = player.player,
					items = Array.map(player.items or {}, MatchPage.makeItemDisplay),
					backpackitems = Array.map(player.backpackitems or {}, MatchPage.makeItemDisplay),
					neutralitem = MatchPage.makeItemDisplay(player.neutralitem or {}),
				})

				newPlayer.displayDamageDone = MatchPage.abbreviateNumber(player.damagedone)
				newPlayer.displayGold = MatchPage.abbreviateNumber(player.gold)

				return newPlayer
			end)

			if game.finished then
				-- Aggregate stats
				team.gold = MatchPage.abbreviateNumber(MatchPage.sumItem(team.players, 'gold'))
				team.kills = MatchPage.sumItem(team.players, 'kills')
				team.deaths = MatchPage.sumItem(team.players, 'deaths')
				team.assists = MatchPage.sumItem(team.players, 'assists')

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
		if game.finished and self.opponents[game.winner] then
			game.winnerName = self.opponents[game.winner].name
		end
	end)
end

function MatchPage:getCharacterIcon(character)
	local characterName = character
	if type(character) == 'table' then
		characterName = character.character
		---@cast character -table
	end
	return CharacterIcon.Icon{
		character = characterName or NO_CHARACTER,
		date = self.matchData.date
	}
end

---@return string
function MatchPage:makeDisplayTitle()
	local team1name = self.opponents[1].teamTemplateData.shortname
	local team2name = self.opponents[2].teamTemplateData.shortname
	if not team1name and team2name then
		return table.concat({'Match in', self.matchData.tickername}, ' ')
	end

	team1name = team1name or 'TBD'
	team2name = team2name or 'TBD'
	local tournamentName = self.matchData.tickername
	local displayTitle = team1name .. ' vs. ' .. team2name
	if not tournamentName then
		return displayTitle
	end

	displayTitle = displayTitle .. ' @ ' .. tournamentName

	mw.getCurrentFrame():preprocess(table.concat{'{{DISPLAYTITLE:', displayTitle, '}}'})
end

function MatchPage.makeItemDisplay(item)
	if String.isEmpty(item.name) then
		return '[[File:EmptyIcon itemicon dota2 gameasset.png|64px|Empty|link=]]'
	end
	return '[[File:'.. item.image ..'|64px|'.. item.name ..'|link=]]'
end

---@return string
function MatchPage:renderGame()
	return TemplateEngine():render(Display.game, Table.merge(self.matchData, self.games))
end

function MatchPage:getPatchLink()
	if Logic.isEmpty(self.matchData.patch) then return end
	return Link{ link = 'Version ' .. self.matchData.patch }
end

return MatchPage
