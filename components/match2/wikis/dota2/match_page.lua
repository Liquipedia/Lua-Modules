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
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchPageWidgets = Lua.import('Module:Widget/Match/Page/All')

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
---@return Widget
function MatchPage.getByMatchId(props)
	---@class Dota2MatchPageViewModel: MatchGroupUtilMatch
	---@field games Dota2MatchPageViewModelGame[]
	---@field opponents Dota2MatchPageViewModelOpponent[]
	local viewModel = props.match

	-- Update the view model with game and team data
	Array.forEach(viewModel.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(Array.range(1, 2), function(teamIdx)
			local team = {
				players = {},
				scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-',
				side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side']),
				objectives = game.extradata['team' .. teamIdx .. 'objectives'],
				picks = Array.filter(game.extradata.vetophase or {}, function(veto)
					return veto.type == 'pick' and veto.team == teamIdx
				end),
				bans = Array.filter(game.extradata.vetophase or {}, function(veto)
					return veto.type == 'ban' and veto.team == teamIdx
				end),
			}

			for _, player in Table.iter.pairsByPrefix(game.participants, teamIdx .. '_') do
				local newPlayer = Table.mergeInto(player, {
					displayName = player.name or player.player,
					link = player.player,
					items = player.items or {},
					backpackitems = player.backpackitems or {},
					neutralitem = player.neutralitem or {},
				})

				table.insert(team.players, newPlayer)
			end

			return team
		end)
		if game.finished and viewModel.opponents[game.winner] then
			game.winnerName = viewModel.opponents[game.winner].name
		end
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

	return HtmlWidgets.Div{
		children = {
			MatchPage.header(viewModel),
			MatchPage.games(viewModel),
			MatchPage.footer(viewModel)
		}
	}
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
---@return Widget
function MatchPage.header(model)
	local phase = MatchGroupUtil.computeMatchPhase(model)
	local phaseDisplay = phase == 'ongoing' and 'live' or phase

	local opponents = Array.map(model.opponents, function(opponent, index)
		local teamTemplate = opponent.template and mw.ext.TeamTemplate.raw(opponent.template)
		if not teamTemplate then
			return {}
		end

		return {
			icon = mw.ext.TeamTemplate.teamicon(opponent.template),
			name = teamTemplate.name,
			shortname = teamTemplate.shortname,
			page = teamTemplate.page,
			seriesDots = Array.map(model.games, function(game)
				return game.teams[index].scoreDisplay
			end),
		}
	end)

	return MatchPageWidgets.header{
		opponents = opponents,
		matchPhase = phaseDisplay,
		parent = model.parent,
		tournament = model.tournament,
		dateCountdown = model.timestamp ~= DateExt.defaultTimestamp and DisplayHelper.MatchCountdownBlock(model) or nil,
		mvp = model.extradata.mvp,
	}
end

---@param model table
---@return string
function MatchPage.games(model)
	local games = Array.map(Array.filter(model.games, function(game)
		return game.resultType ~= NOT_PLAYED
	end), MatchPage.game)

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

---@param game table
---@return Widget
function MatchPage.game(game)
	return HtmlWidgets.Fragment{
		children = {
			MatchPageWidgets.MatchPageGameDraft{
				opponents = Array.map(game.teams, function(opponent)
					return {
						icon = opponent.icon,
						picks = opponent.picks,
						bans = opponent.bans,
						side = opponent.side,
					}
				end),
			},
			MatchPageWidgets.MatchPageGameStats{
				opponents = Array.map(game.teams, function(opponent)
					return {
						icon = opponent.icon,
						side = opponent.side,
						score = opponent.scoreDisplay,
						kills = MatchPage._sumItem(opponent.players, 'kills'),
						deaths = MatchPage._sumItem(opponent.players, 'deaths'),
						assists = MatchPage._sumItem(opponent.players, 'assists'),
						gold = MatchPage._sumItem(opponent.players, 'gold'),
						towers = opponent.objectives.towers,
						barracks = opponent.objectives.barracks,
						roshans = opponent.objectives.roshans,
					}
				end),
				length = game.length,
				winner = game.winnerName,
				children = {
					{
						render = function(team)
							if not team.kills or not team.deaths or not team.assists then
								return ''
							end
							return team.kills .. '/' .. team.deaths .. '/' .. team.assists
						end,
						icon = '<i class="fas fa-skull-crossbones"></i>',
						text = 'KDA',
					},
					{
						render = function(team) return MatchPage._abbreviateNumber(team.gold) end,
						icon = '<i class="fas fa-coins"></i>',
						text = 'Gold',
					},
					{
						render = function(team) return team.towers end,
						icon = '<i class="fas fa-chess-rook"></i>',
						text = 'Towers',
					},
					{
						render = function(team) return team.barracks end,
						icon = '<i class="fas fa-warehouse"></i>',
						text = 'Barracks',
					},
					{
						render = function(team) return team.roshans end,
						icon = '<i class="liquipedia-custom-icon liquipedia-custom-icon-roshan"></i>',
						text = 'Roshan',
					},
				}
			},
			MatchPageWidgets.MatchPageGamePlayers{
				opponents = Array.map(game.teams, function (opponent)
					return {
						icon = opponent.icon,
						players = opponent.players,
					}
				end)
			},
		}
	}
end

---@param model table
---@return Widget
function MatchPage.footer(model)
	local vods = Array.map(model.games, function(game, gameIdx)
		return game.vod and VodLink.display{
			gamenum = gameIdx,
			vod = game.vod,
		} or ''
	end)

	-- Create an object array for links
	local function processLink(site, link)
		return Table.mergeInto({link = link}, MatchLinks[site])
	end

	local links = Array.flatMap(Table.entries(model.links), function(linkData)
		local site, link = unpack(linkData)
		if type(link) == 'table' then
			return Array.map(link, function(sublink)
				return processLink(site, sublink)
			end)
		end
		return {processLink(site, link)}
	end)

	return MatchPageWidgets.footer{
		vods = vods,
		links = links,
		patch = model.patch,
	}
end

return MatchPage
