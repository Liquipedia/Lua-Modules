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
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Links = require('Module:Links')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TeamTemplate = require('Module:TeamTemplate')
local VodLink = require('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local AdditionalSection = Lua.import('Module:Widget/Match/Page/AdditionalSection')
local Div = HtmlWidgets.Div
local Footer = Lua.import('Module:Widget/Match/Page/Footer')
local Header = Lua.import('Module:Widget/Match/Page/Header')
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
		self.games = match.games
		self.opponents = match.opponents
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

---@protected
---@return Html?
function BaseMatchPage:getCountdownBlock()
	if self.matchData.timestamp == DateExt.defaultTimestamp then return end
	return DisplayHelper.MatchCountdownBlock(self.matchData)
end

---@private
---@param site string
---@param link string
---@return {icon: string, iconDark: string?, link: string, text: string}?
function BaseMatchPage._processLink(site, link)
	return Table.mergeInto({link = link}, Links.getMatchIconData(site))
end

---Creates an object array for links
---@private
---@return {icon: string, iconDark: string?, link: string, text: string}[]
function BaseMatchPage:_parseLinks()
	return Array.flatMap(Table.entries(self.matchData.links), function(linkData)
		local site, link = unpack(linkData)
		if type(link) == 'table' then
			return Array.map(link, function(sublink)
				return BaseMatchPage._processLink(site, sublink)
			end)
		end
		return {BaseMatchPage._processLink(site, link)}
	end)
end

---@protected
---@return (string|Html)[]
function BaseMatchPage:getVods()
	local vods = Array.map(self.games, function(game, gameIdx)
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

---@protected
function BaseMatchPage:populateGames()
	error('BaseMatchPage:populateGames() cannot be called directly and must be overridden.')
end

---@protected
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

---@protected
function BaseMatchPage:getCharacterIcon(character)
	error('BaseMatchPage:getCharacterIcon() cannot be called directly and must be overridden.')
end

---@protected
function BaseMatchPage:makeDisplayTitle()
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

	mw.getCurrentFrame():preprocess(table.concat{'{{DISPLAYTITLE:', displayTitle, '|noreplace}}'})
end

---@return Widget
function BaseMatchPage:render()
	self:makeDisplayTitle()
	return Div{
		children = WidgetUtil.collect(
			Header {
				countdownBlock = self:getCountdownBlock(),
				isBestOfOne = self:isBestOfOne(),
				mvp = self.matchData.extradata.mvp,
				opponent1 = self.matchData.opponents[1],
				opponent2 = self.matchData.opponents[2],
				parent = self.matchData.parent,
				phase = MatchGroupUtil.computeMatchPhase(self.matchData),
				tournamentName = self.matchData.tournament,
			},
			self:renderGames(),
			self:footer()
		)
	}
end

---@protected
---@return string|Html|Widget?
function BaseMatchPage:renderGames()
	local games = Array.map(Array.filter(self.games, function(game)
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

---@protected
---@param game MatchGroupUtilGame
---@return string|Html|Widget
function BaseMatchPage:renderGame(game)
	error('BaseMatchPage:renderGame() cannot be called directly and must be overridden.')
end

---@protected
---@return Widget
function BaseMatchPage:footer()
	local vods = self:getVods()
	return Footer{
		children = WidgetUtil.collect(
			#vods > 0 and AdditionalSection{
				header = 'VODs',
				children = vods
			} or nil,
			AdditionalSection{
				header = 'Links',
				bodyClasses = { 'vodlink' },
				children = Array.map(self:_parseLinks(), function (parsedLink)
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
end

---@protected
function BaseMatchPage:getPatchLink()
	if Logic.isEmpty(self.matchData.patch) then return end
	return Link{ link = 'Patch ' .. self.matchData.patch }
end

return BaseMatchPage
