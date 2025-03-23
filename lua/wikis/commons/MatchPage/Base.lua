---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchPage/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Links = require('Module:Links')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table') ---@module 'commons.Table'
local Tabs = require('Module:Tabs')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'
local VodLink = require('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local AdditionalSection = Lua.import('Module:Widget/Match/MatchPage/AdditionalSection')
local Div = HtmlWidgets.Div
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageMatch: MatchGroupUtilMatch
---@field parent string?
---@field patch string?

---@class MatchPageGame: MatchGroupUtilGame
---@field finished boolean
---@field winnerName string?
---@field teams table[]
---@field scoreDisplay string

---@class MatchPageOpponent: standardOpponent
---@field opponentIndex integer
---@field iconDisplay string
---@field teamTemplateData teamTemplateData
---@field seriesDots string[]

---@class BaseMatchPage
---@operator call(MatchPageMatch): self
---@field matchData MatchPageMatch
---@field games MatchPageGame[]
---@field opponents MatchPageOpponent[]
local BaseMatchPage = Class.new(
	---@param self self
	---@param match MatchGroupUtilMatch
	function (self, match)
		self.matchData = match
		self.games = Table.deepCopy(match.games)
		self.opponents = Table.deepCopy(match.opponents)
	end
)

BaseMatchPage.NOT_PLAYED = 'notplayed'

---@param match table
---@return boolean
function BaseMatchPage.isEnabledFor(match)
	error('BaseMatchPage.isEnabledFor() cannot be called directly and must be overridden.')
end

---@param props {match: MatchGroupUtilMatch}
---@return Widget
function BaseMatchPage.getByMatchId(props)
	local matchPage = BaseMatchPage(props.match)
	return matchPage:render()
end

---Tests whether this match page is a Bo1
---@return boolean
function BaseMatchPage:isBestOfOne()
	return #self.matchData.games == 1
end

---@return Html?
function BaseMatchPage:getCountdownBlock()
	if self.matchData.timestamp == DateExt.defaultTimestamp then return end
	return DisplayHelper.MatchCountdownBlock(self.matchData)
end

---Creates an object array for links
---@return {icon: string, iconDark: string?, link: string, text: string}[]
function BaseMatchPage:parseLinks()
	return Array.extractValues(Table.map(self.matchData.links, function(site, link)
		return site, Table.mergeInto({link = link}, Links.getMatchIconData(site))
	end))
end

---@return (string|Html)[]
function BaseMatchPage:getVods()
	local vods =  Array.map(self.games, function(game, gameIdx)
		return game.vod and VodLink.display{
			gamenum = gameIdx,
			vod = game.vod,
		} or ''
	end)
	if String.isNotEmpty(self.matchData.vod) then
		table.insert(vods, 1, VodLink.display{
			vod = self.matchData.vod,
		})
	end
	return vods
end

---@param arr any[]
---@param item string
---@return number
function BaseMatchPage.sumItem(arr, item)
	return Array.reduce(Array.map(arr, Operator.property(item)), Operator.add, 0)
end

---@param number number?
---@return string?
function BaseMatchPage.abbreviateNumber(number)
	if not number then
		return
	end
	return string.format('%.1fK', number / 1000)
end

function BaseMatchPage:populateGames()
	error('BaseMatchPage.populateGames() cannot be called directly and must be overridden.')
end

function BaseMatchPage:populateOpponents()
	Array.forEach(self.opponents, function(opponent, index)
		opponent.opponentIndex = index

		local teamTemplate = opponent.template and TeamTemplate.getRawOrNil(opponent.template)
		if not teamTemplate then
			return
		end

		opponent.iconDisplay = mw.ext.TeamTemplate.teamicon(opponent.template)
		opponent.teamTemplateData = teamTemplate

		opponent.seriesDots = Array.map(self.games, function(game)
			return game.teams[index].scoreDisplay
		end)
	end)
end

function BaseMatchPage:getCharacterIcon(character)
	error('BaseMatchPage.getCharacterIcon() cannot be called directly and must be overridden.')
end

function BaseMatchPage:makeDisplayTitle()
end

---@return Widget
function BaseMatchPage:render()
	self:makeDisplayTitle()
	return Div{
		children = WidgetUtil.collect(
			self:header(),
			self:renderGames(),
			self:footer()
		)
	}
end

---@return Widget[]
function BaseMatchPage:header()
	return WidgetUtil.collect(
		Div{
			classes = { 'match-bm-lol-match-header' },
			children = {
				Div{
					classes = { 'match-bm-match-header-powered-by' },
					children = {
						'Data provided by ',
						Image.display('SAP logo.svg', nil, {link = '', alt = 'SAP'})
					}
				},
				Div{
					classes = { 'match-bm-lol-match-header-overview' },
					children = {
						self:_makeTeamDisplay(self.opponents[1]),
						self:_makeResultDisplay(),
					self:_makeTeamDisplay(self.opponents[2])
					}
				},
				Div{
					classes = { 'match-bm-lol-match-header-tournament' },
					children = {
						Link{ link = self.matchData.parent, children = self.matchData.tournament }
					}
				},
				Div{
					classes = { 'match-bm-lol-match-header-date' },
					children = { self:getCountdownBlock() }
				}
			},

		},
		self:_showMvps()
	)
end

---comment
---@param opponent MatchPageOpponent
---@return Widget
function BaseMatchPage:_makeTeamDisplay(opponent)
	local data = opponent.teamTemplateData
	return Div{
		classes = { 'match-bm-match-header-team' },
		children = {
			mw.ext.TeamTemplate.teamicon(data.templatename),
			Div{
				classes = { 'match-bm-match-header-team-group' },
				children = {
					Div{
						classes = { 'match-bm-match-header-team-long' },
						children = { Link{ link = data.page } }
					},
					Div{
						classes = { 'match-bm-match-header-team-short' },
						children = { Link{ link = data.page, children = data.shortname } }
					},
					Div{
						classes = { 'match-bm-lol-match-header-round-results' },
						children = Array.map(opponent.seriesDots, BaseMatchPage._makeGameResultIcon)
					},
				}
			}
		}
	}
end

---@param result 'winner'|'loser'|'-'
---@return Widget
function BaseMatchPage._makeGameResultIcon(result)
	return Div{
		classes = { 'match-bm-lol-match-header-round-result', 'result--' .. result }
	}
end

---@return Widget
function BaseMatchPage:_makeResultDisplay()
	local phase = MatchGroupUtil.computeMatchPhase(self.matchData)
	return Div{
		classes = { 'match-bm-match-header-result' },
		children = {
			self:isBestOfOne() and '' or (self.opponents[1].score .. '&ndash;' .. self.opponents[2].score),
			Div{
				classes = { 'match-bm-match-header-result-text' },
				children = { phase == 'ongoing' and 'live' or phase }
			}
		}
	}
end

---@return Widget?
function BaseMatchPage:_showMvps()
	local mvpData = self.matchData.extradata.mvp
	if Logic.isEmpty(mvpData) then return end
	return Div{
		classes = { 'match-bm-lol-match-mvp' },
		children = WidgetUtil.collect(
			HtmlWidgets.B{ children = { 'MVP' } },
			unpack(Array.interleave(Array.map(mvpData.players, function (player)
				return Link{ link = player.name, children = player.displayname }
			end), ' '))
		)
	}
end

---@return string|Html|Widget?
function BaseMatchPage:renderGames()
	local games = Array.map(Array.filter(self.matchData.games, function(game)
		return game.status ~= BaseMatchPage.NOT_PLAYED
	end), function(game)
		return self:renderGame(game)
	end)

	if #games < 2 then
		return games[1]
	end

	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true
	}

	Array.forEach(games, function(game, idx)
		tabs['name' .. idx] = 'Game ' .. idx
		tabs['content' .. idx] = game
	end)

	return Tabs.dynamic(tabs)
end

---@param game MatchGroupUtilGame
---@return string|Html|Widget
function BaseMatchPage:renderGame(game)
	error('BaseMatchPage:renderGame() cannot be called directly and must be overridden.')
end

---@return string|Html|Widget
function BaseMatchPage:footer()
	local vods = self:getVods()
	return {
		HtmlWidgets.H3{ children = 'Additional Information' },
		Div{
			classes = { 'match-bm-match-additional' },
			children = WidgetUtil.collect(
				#vods > 0 and AdditionalSection{
					header = 'VODs',
					children = vods
				} or nil,
				AdditionalSection{
					bodyClasses = { 'vodlink' },
					children = Array.map(self:parseLinks(), function (parsedLink)
						return IconImage{
							imageLight = parsedLink.icon:sub(6),
							imageDark = (parsedLink.iconDark or parsedLink.icon):sub(6),
							link = parsedLink.link
						}
					end)
				},
				AdditionalSection{
					header = 'Patch',
					children = { self:getPatchLink() }
				}
			)
		}
	}
end

function BaseMatchPage:getPatchLink()
	if Logic.isEmpty(self.matchData.patch) then return end
	return Link{ link = 'Patch ' .. self.matchData.patch }
end

return BaseMatchPage
