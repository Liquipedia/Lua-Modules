---
-- @Liquipedia
-- page=Module:MatchPage/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
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

local HighlightConditions = Lua.import('Module:HighlightConditions')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local AdditionalSection = Lua.import('Module:Widget/Match/Page/AdditionalSection')
local MatchPageMapVeto = Lua.import('Module:Widget/Match/Page/MapVeto')
local Comment = Lua.import('Module:Widget/Match/Page/Comment')
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
---@field teams table[]
---@field scoreDisplay string

---@class MatchPageOpponent: standardOpponent
---@field opponentIndex integer
---@field iconDisplay string
---@field teamTemplateData teamTemplateData
---@field seriesDots string[]

---@class BaseMatchPage
---@operator call(MatchPageMatch): BaseMatchPage
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
BaseMatchPage.NO_CHARACTER = 'default'

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
---@param character string?
---@return string?
function BaseMatchPage:getCharacterIcon(character)
	return CharacterIcon.Icon{
		character = character or BaseMatchPage.NO_CHARACTER,
		date = self.matchData.date
	}
end

---@protected
---@return string
function BaseMatchPage:makeDisplayTitle()
	local team1data = (self.opponents[1] or {}).teamTemplateData
	local team2data = (self.opponents[2] or {}).teamTemplateData
	local tournamentName = self.matchData.tickername

	if Logic.isEmpty(team1data) and Logic.isEmpty(team2data) then
		return String.isNotEmpty(tournamentName) and 'Match in ' .. tournamentName or ''
	end

	local team1name = (team1data or {}).shortname or 'TBD'
	local team2name = (team2data or {}).shortname or 'TBD'

	local titleParts = {team1name, 'vs.', team2name}
	if tournamentName then
		Array.appendWith(titleParts, '@', tournamentName)
	end

	return table.concat(titleParts, ' ')
end

---@return Widget
function BaseMatchPage:render()
	local displayTitle = self:makeDisplayTitle()
	if String.isNotEmpty(displayTitle) then
		mw.getCurrentFrame():callParserFunction('DISPLAYTITLE', displayTitle, 'noreplace')
	end

	local tournamentContext = self:_getMatchContext()
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
				poweredBy = self.getPoweredBy(),
				highlighted = HighlightConditions.tournament(tournamentContext),
			},
			self:renderMapVeto(),
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
		local mapName = self.games[idx].map
		if Logic.isNotEmpty(mapName) then
			tabs['name' .. idx] = 'Game ' .. idx .. ': ' .. mapName
		else
			tabs['name' .. idx] = 'Game ' .. idx
		end
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

---@private
---@return table
function BaseMatchPage:_getMatchContext()
	return MatchGroupInputUtil.getTournamentContext(self.matchData)
end

---@protected
---@return Widget[]
function BaseMatchPage:renderMapVeto()
	local match = self.matchData
	if not match.extradata or not match.extradata.mapveto then
		return {}
	end

	local mapVetoes = match.extradata.mapveto
	local firstVeto = tonumber(mapVetoes[1].vetostart)

	if not firstVeto or not (firstVeto == 1 or firstVeto == 2) then
		return {}
	end

	local secondVeto = firstVeto == 1 and 2 or 1

	local opponent1 = match.opponents[firstVeto]
	local opponent2 = match.opponents[secondVeto]

	local mapVetoRounds = Array.flatMap(mapVetoes, function(vetoRound, vetoRoundIdx)
		local vetoRoundFirst = vetoRoundIdx * 2 - 1
		local vetoRoundSecond = vetoRoundIdx * 2
		if vetoRound.type == 'decider' then
			return {{map = vetoRound.decider, type = vetoRound.type, round = vetoRoundFirst}}
		end
		local firstMap = vetoRound['team' .. firstVeto]
		local secondMap = vetoRound['team' .. secondVeto]
		return {
			{map = firstMap, type = vetoRound.type, round = vetoRoundFirst, by = opponent1},
			{map = secondMap, type = vetoRound.type, round = vetoRoundSecond, by = opponent2},
		}
	end)

	return {
		HtmlWidgets.H3{children = 'Map Veto'},
		MatchPageMapVeto{vetoRounds = mapVetoRounds},
	}
end

---@protected
---@return Widget
function BaseMatchPage:footer()
	local vods = self:getVods()
	return Footer{
		comments = self:_getComments(),
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

---@private
---@return MatchPageComment[]
function BaseMatchPage:_getComments()
	local substituteComments = DisplayHelper.createSubstitutesComment(self.matchData)
	return WidgetUtil.collect(
		self.matchData.comment and Comment{children = self.matchData.comment} or nil,
		Logic.isNotEmpty(substituteComments) and Comment{
			children = Array.interleave(substituteComments, HtmlWidgets.Br{})
		} or nil,
		self:_getCasterComment(),
		self:addComments()
	)
end

---@private
---@return MatchPageComment?
function BaseMatchPage:_getCasterComment()
	local casters = self.matchData.extradata.casters
	if Logic.isEmpty(casters) then return end
	return Comment{
		children = WidgetUtil.collect(
			#casters > 1 and 'Casters: ' or 'Caster: ',
			Array.interleave(DisplayHelper.createCastersDisplay(casters), ', ')
		)
	}
end

---@protected
---@return MatchPageComment[]
function BaseMatchPage:addComments()
	return {}
end

---@protected
function BaseMatchPage:getPatchLink()
	if Logic.isEmpty(self.matchData.patch) then return end
	return Link{ link = 'Patch ' .. self.matchData.patch }
end

---@protected
---@return string?
function BaseMatchPage.getPoweredBy()
	return nil
end

return BaseMatchPage
