---
-- @Liquipedia
-- page=Module:MatchPage/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')
local Links = Lua.import('Module:Links')
local MatchTable = Lua.import('Module:MatchTable')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TextSanitizer = Lua.import('Module:TextSanitizer')
local Tournament = Lua.import('Module:Tournament')

local HighlightConditions = Lua.import('Module:HighlightConditions')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local AdditionalSection = Lua.import('Module:Widget/Match/Page/AdditionalSection')
local MatchPageMapVeto = Lua.import('Module:Widget/Match/Page/MapVeto')
local Comment = Lua.import('Module:Widget/Match/Page/Comment')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local Div = HtmlWidgets.Div
local Footer = Lua.import('Module:Widget/Match/Page/Footer')
local Header = Lua.import('Module:Widget/Match/Page/Header')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local VodButton = Lua.import('Module:Widget/Match/VodButton')

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
---@field iconDisplay Widget?
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

		-- Update the view model with game and team data
		self:populateGames()

		-- Add more opponent data field
		self:populateOpponents()

		self:addCategories()

		self:_setMetadata()
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

function BaseMatchPage:addCategories()
	local matchPhase = MatchGroupUtil.computeMatchPhase(self.matchData)

	mw.ext.TeamLiquidIntegration.add_category('Matches')
	if matchPhase then
		local phaseToDisplay = {
			finished = 'Finished',
			ongoing = 'Live',
			upcoming = 'Upcoming',
		}
		if phaseToDisplay[matchPhase] then
			mw.ext.TeamLiquidIntegration.add_category(phaseToDisplay[matchPhase] .. ' Matches')
		end
	end
end

---@private
function BaseMatchPage:_setMetadata()
	local tournament = self:getMatchContext()
	local icon = Logic.emptyOr(tournament.icon, tournament.iconDark)

	if icon then
		mw.ext.SearchEngineOptimization.metaimage(icon)
	end

	local desc = self:seoText()
	if String.isNotEmpty(desc) then
		---@cast desc -nil
		mw.ext.SearchEngineOptimization.metadescl(desc)
	end
end

---@protected
function BaseMatchPage:seoText()
	local tournament = self:getMatchContext()
	local matchPhase = MatchGroupUtil.computeMatchPhase(self.matchData)

	---@return string?
	local function createTenseString()
		if matchPhase == 'ongoing' then
			return
		end
		return String.interpolate(
			' that ${tense} place on ${date}',
			{
				tense = matchPhase == 'upcoming' and 'will take' or 'took',
				date = TextSanitizer.stripHTML(DateExt.toCountdownArg(
					self.matchData.timestamp, self.matchData.timezoneId, self.matchData.dateIsExact
				))
			}
		)
	end

	return I18n.translate(
		(Opponent.isTbd(self.opponents[1]) and Opponent.isTbd(self.opponents[2]))
			and 'matchpage-meta-desc-no-opponent' or 'matchpage-meta-desc',
		{
			ongoingTense = matchPhase == 'ongoing' and 'ongoing ' or '',
			game = (Game.name{game = self.matchData.game}) --[[@as string]],
			tournamentName = tournament.displayName,
			opponent1 = Opponent.toName(self.opponents[1]),
			opponent2 = Opponent.toName(self.opponents[2]),
			tense = createTenseString() or ''
		}
	)
end

---Tests whether this match page is a Bo1
---@return boolean
function BaseMatchPage:isBestOfOne()
	return #self.matchData.games == 1
end

---@protected
---@return Widget?
function BaseMatchPage:getCountdownBlock()
	if DateExt.isDefaultTimestamp(self.matchData.timestamp) then return end
	return Div{
		css = {
			display = 'block',
			['text-align'] = 'center'
		},
		children = Countdown.create{
			date = DateExt.toCountdownArg(self.matchData.timestamp, self.matchData.timezoneId, self.matchData.dateIsExact),
			finished = self.matchData.finished,
			rawdatetime = (not self.matchData.dateIsExact) or self.matchData.finished,
		}
	}
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
---@return Widget[]
function BaseMatchPage:getVods()
	---@type {vod: string, number: integer}[]
	local gameVods = Array.map(self.games, function(game, gameIdx)
		if Logic.isEmpty(game.vod) then
			return
		end
		return {
			vod = game.vod,
			number = gameIdx,
		}
	end)

	return WidgetUtil.collect(
		String.isNotEmpty(self.matchData.vod) and VodButton{
			vodLink = self.matchData.vod,
			grow = true,
		} or nil,
		Array.map(gameVods, function (vod)
			return VodButton{
				vodLink = vod.vod,
				gameNumber = vod.number,
				showText = #gameVods < 4,
				variant = 'dropdown',
				grow = true,
			}
		end)
	)
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

		opponent.iconDisplay = OpponentDisplay.InlineTeamContainer{
			style = 'icon',
			template = opponent.template
		}
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
	local tournamentName = self:getMatchContext().displayName

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

	local tournamentContext = self:getMatchContext()
	return Div{
		classes = {'match-bm'},
		children = WidgetUtil.collect(
			Header {
				countdownBlock = self:getCountdownBlock(),
				isBestOfOne = self:isBestOfOne(),
				mvp = self.matchData.extradata.mvp,
				opponent1 = self.matchData.opponents[1],
				opponent2 = self.matchData.opponents[2],
				parent = self.matchData.parent,
				phase = MatchGroupUtil.computeMatchPhase(self.matchData),
				stream = self.matchData.stream,
				tournamentName = self.matchData.tournament,
				poweredBy = self.getPoweredBy(),
				highlighted = HighlightConditions.tournament(tournamentContext),
			},
			self:renderMapVeto(),
			self:renderGames(),
			self:footer(),
			self:previousMatches()
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

	local overallStats = self:renderOverallStats()

	return ContentSwitch{
		css = {
			['margin-top'] = '0.5rem',
			['margin-bottom'] = '0.5rem',
		},
		tabs = WidgetUtil.collect(
			overallStats and {
				label = {
					HtmlWidgets.Span{classes = {'mobile-hide'}, children = 'Overall Statistics'},
					HtmlWidgets.Span{classes = {'mobile-only'}, children = 'Overall'}
				},
				content = overallStats
			} or nil,
			Array.map(games, function (game, gameIndex)
				local mapName = self.games[gameIndex].map
				return {
					label = 'Game&nbsp;' .. gameIndex .. (
						Logic.isNotEmpty(mapName) and (': ' .. mapName) or ''
					),
					content = game
				}
			end)
		),
		size = 'small',
		storeValue = false,
		switchGroup = 'matchPageGameSelector',
		variant = 'generic'
	}
end

---@protected
---@return string|Html|Widget?
function BaseMatchPage:renderOverallStats()
	return nil
end

---@protected
---@param game MatchGroupUtilGame
---@return string|Html|Widget
function BaseMatchPage:renderGame(game)
	error('BaseMatchPage:renderGame() cannot be called directly and must be overridden.')
end

---@protected
---@param self BaseMatchPage
---@return StandardTournamentPartial
BaseMatchPage.getMatchContext = FnUtil.memoize(function (self)
	return Tournament.partialTournamentFromMatch(self.matchData)
end)

---@protected
---@return Widget
function BaseMatchPage:getTournamentIcon()
	return IconImage{
		imageLight = self:getMatchContext().icon,
		imageDark = self:getMatchContext().iconDark,
		size = '50x32px',
	}
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
	local parsedLinks = self:_parseLinks()
	local patchLink = self:getPatchLink()

	return Footer{
		comments = self:_getComments(),
		children = WidgetUtil.collect(
			Logic.isNotEmpty(vods) and AdditionalSection{
				header = 'VODs',
				children = vods
			} or nil,
			Logic.isNotEmpty(parsedLinks) and AdditionalSection{
				header = 'Links',
				bodyClasses = { 'vodlink' },
				children = Array.map(parsedLinks, function (parsedLink)
					return HtmlWidgets.Span{children = IconImage{
						imageLight = parsedLink.icon,
						imageDark = (parsedLink.iconDark or parsedLink.icon),
						link = parsedLink.link
					}}
				end)
			} or nil,
			patchLink and AdditionalSection{
				header = 'Patch',
				children = patchLink
			} or nil
		)
	}
end

---@protected
---@return Widget[]?
function BaseMatchPage:previousMatches()
	if Array.all(self.opponents, Opponent.isTbd) then
		return
	end

	local headToHead = self:_buildHeadToHeadMatchTable()

	return WidgetUtil.collect(
		HtmlWidgets.H3{children = 'Match History'},
		Div{
			classes = {'match-bm-match-additional'},
			children = WidgetUtil.collect(
				headToHead and AdditionalSection{
					css = {flex = '2 0 100%'},
					header = 'Head to Head',
					bodyClasses = {'match-table-wrapper'},
					children = headToHead,
				} or nil,
				Array.map(self.opponents, function (opponent)
					local matchTable = self:_buildMatchTable(opponent)
					return AdditionalSection{
						header = OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'hybrid'},
						bodyClasses = matchTable and {'match-table-wrapper'} or nil,
						children = matchTable or self:getTournamentIcon()
					}
				end)
			)
		}
	)
end

---@private
---@param opponent standardOpponent
---@return boolean
function BaseMatchPage._isTeamOpponent(opponent)
	return not Opponent.isTbd(opponent) and opponent.type == Opponent.team
end

---@private
---@param props table
---@return Html
function BaseMatchPage:_createMatchTable(props)
	return MatchTable(Table.mergeInto({
		addCategory = false,
		dateFormat = 'compact',
		edate = self.matchData.timestamp - DateExt.daysToSeconds(1) --[[ MatchTable adds 1-day offset to make edate
																		inclusive, and we don't want that here ]],
		limit = 5,
		stats = false,
		tableMode = Opponent.team,
		vod = false,
		matchPageButtonText = 'short',
	}, props)):readConfig():query():buildDisplay()
end

---@private
---@param opponent standardOpponent
---@return Html?
function BaseMatchPage:_buildMatchTable(opponent)
	if not BaseMatchPage._isTeamOpponent(opponent) then
		return
	end
	return self:_createMatchTable{
		['hide_tier'] = true,
		limit = 5,
		stats = false,
		tableMode = Opponent.team,
		team = opponent.name,
		useTickerName = true,
	}
end

---@private
---@return Html?
function BaseMatchPage:_buildHeadToHeadMatchTable()
	if not Array.all(self.opponents, BaseMatchPage._isTeamOpponent) then
		return
	end
	return self:_createMatchTable{
		team = self.opponents[1].name,
		vsteam = self.opponents[2].name,
		showOpponent = true,
		teamStyle = 'hybrid',
		useTickerName = true,
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
---@return Widget?
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
