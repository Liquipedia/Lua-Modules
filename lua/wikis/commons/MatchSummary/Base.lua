---
-- @Liquipedia
-- page=Module:MatchSummary/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local VodLink = Lua.import('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Links = Lua.import('Module:Links')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local MatchButtonBar = Lua.import('Module:Widget/Match/ButtonBar')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MATCH_LINK_PRIORITY = Lua.import('Module:Links/MatchPriorityGroups', {loadData = true})
local TBD = Abbreviation.make{text = 'TBD', title = 'To Be Determined'}

---@class MatchSummaryFooter
---@operator call: MatchSummaryFooter
---@field elements (Widget|Html|string|number)[]
local Footer = Class.new(
	function(self)
		self.elements = {}
	end
)

---@param element Widget|Html|string|number|nil
---@return MatchSummaryFooter
function Footer:addElement(element)
	table.insert(self.elements, element)
	return self
end

---@param link string
---@param icon string
---@param iconDark string?
---@param text string
---@return MatchSummaryFooter
function Footer:addLink(link, icon, iconDark, text)
	table.insert(self.elements, Image.display(icon, iconDark, {
		link = link, size = '32px', caption = text, alt = link
	}))
	return self
end

---@param links table<string, string|table>
---@return MatchSummaryFooter
function Footer:addLinks(links)
	local processLink = function(linkType, link)
		local currentLinkData = Links.getMatchIconData(linkType)
		if not currentLinkData then
			mw.log('Unknown link: ' .. linkType)
		elseif type(link) == 'table' then
			for gameIdx, gameLink in Table.iter.spairs(link) do
				local newText = currentLinkData.text .. ' on Game ' .. gameIdx
				self:addLink(gameLink, currentLinkData.icon, currentLinkData.iconDark, newText)
			end
		else
			self:addLink(link, currentLinkData.icon, currentLinkData.iconDark, currentLinkData.text)
		end
	end

	local processedLinks = {}
	Array.forEach(MATCH_LINK_PRIORITY, function(linkType)
		for linkKey, link in Table.iter.pairsByPrefix(links, linkType, {requireIndex = false}) do
			processLink(linkKey, link)
			processedLinks[linkKey] = true
		end
	end)

	for linkKey, link in Table.iter.spairs(links) do
		-- Handle links not already processed via priority list
		if not processedLinks[linkKey] then
			processLink(linkKey, link)
		end
	end

	return self
end

---@return Widget?
function Footer:create()
	return MatchSummaryWidgets.Footer{children = self.elements}
end

---@class MatchSummaryMatch
---@operator call: MatchSummaryMatch
---@field root Html
---@field headerElement Widget?
---@field bodyElement Widget[]?
---@field commentElement Widget?
---@field footerElement Widget?
---@field buttonElement Widget?
local Match = Class.new(
	function(self)
		self.root = mw.html.create()
	end
)

---@param header Widget
---@return MatchSummaryMatch
function Match:header(header)
	self.headerElement = header
	return self
end

---@param body Widget[]
---@return MatchSummaryMatch
function Match:body(body)
	self.bodyElement = body
	return self
end

---@param comment Widget
---@return MatchSummaryMatch
function Match:comment(comment)
	self.commentElement = comment
	return self
end

---@param footer MatchSummaryFooter
---@return MatchSummaryMatch
function Match:footer(footer)
	self.footerElement = footer:create()
	return self
end

---@param button Widget
---@return MatchSummaryMatch
function Match:button(button)
	self.buttonElement = button
	return self
end

---@return Html
function Match:create()
	self.root
		:node(self.headerElement)
		:node(
			MatchSummaryWidgets.Body{children = WidgetUtil.collect(self.bodyElement, self.commentElement, self.footerElement)}
		)
		:node(self.buttonElement)

	return self.root
end

---@class MatchSummary
local MatchSummary = {
	Footer = Footer,
	Match = Match,
}

---Default header function
---@param match table
---@param options {teamStyle: teamStyle?}?
---@return Widget
function MatchSummary.createDefaultHeader(match, options)
	options = options or {}

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			MatchCountdown{
				match = match,
			},
			MatchHeader{
				match = match,
				teamStyle = options.teamStyle,
			}
		)
	}
end

-- Default body function
---@param match MatchGroupUtilMatch
---@param createGame fun(date: string, game: table, gameIndex: integer): Widget
---@return Widget[]
function MatchSummary.createDefaultBody(match, createGame)
	return WidgetUtil.collect(
		Array.map(match.games, FnUtil.curry(createGame, match.date)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game}))
	)
end

---Default footer function
---@param match table
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function MatchSummary.createDefaultFooter(match, footer)
	return MatchSummary.addVodsToFooter(match, footer):addLinks(match.links)
end

---Creates a match footer with vods if vods are set
---@param match table
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function MatchSummary.addVodsToFooter(match, footer)
	if match.vod then
		footer:addElement(VodLink.display{
			vod = match.vod,
		})
	end

	Array.forEach(match.games, function(game, gameIndex)
		if not game.vod then
			return
		end
		footer:addElement(VodLink.display{
			gamenum = gameIndex,
			vod = game.vod,
		})
	end)

	return footer
end

---Default createMatch function for usage in Custom MatchSummary
---@param matchData MatchGroupUtilMatch?
---@param CustomMatchSummary table
---@param options {teamStyle: teamStyle?, noScore: boolean?}?
---@return MatchSummaryMatch?
function MatchSummary.createMatch(matchData, CustomMatchSummary, options)
	if not matchData then
		return
	end

	local match = Match()

	local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
	match:header(createHeader(matchData, options))

	local createBody = CustomMatchSummary.createBody or MatchSummary.createDefaultBody
	match:body(createBody(matchData, CustomMatchSummary.createGame))

	local substituteComment = DisplayHelper.createSubstitutesComment(matchData)

	match:comment(HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			MatchSummaryWidgets.Casters{casters = matchData.extradata.casters},
			MatchSummaryWidgets.MatchComment{
				children = WidgetUtil.collect(
					matchData.comment,
					substituteComment
				)
			}
		)
	})

	local createFooter = CustomMatchSummary.addToFooter or MatchSummary.createDefaultFooter
	match:footer(createFooter(matchData, MatchSummary.Footer()))

	--- Vods are currently part of the footer, so we don't need them here
	match:button(MatchButtonBar{match = matchData, showVods = false, variant = 'primary'})

	return match
end

---Default getByMatchId function for usage in Custom MatchSummary
---@param CustomMatchSummary table
---@param args table
---@param options {teamStyle:teamStyle?, width: fun(MatchGroupUtilMatch):string?|string?, noScore:boolean?}?
---@return Widget
function MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
	assert(
		(type(CustomMatchSummary.createBody) == 'function' or type(CustomMatchSummary.createGame) == 'function'),
		'createBody(match) or createGame(date, game, gameIndex) must be implemented in Module:MatchSummary'
	)

	options = options or {}

	local match, bracketResetMatch = MatchGroupUtil.fetchMatchForBracketDisplay(
		args.bracketId, args.matchId)

	local width = options.width
	if type(width) == 'function' then
		width = width(match)
	end

	return MatchSummaryWidgets.Container{
		width = width,
		createMatch = CustomMatchSummary.createMatch or function(matchData)
			return MatchSummary.createMatch(matchData, CustomMatchSummary, options)
		end,
		match = match,
		resetMatch = bracketResetMatch,
	}
end

---@param mapVetoes table
---@param options {game: string?, emptyMapDisplay: string?}?
---@return {firstVeto: integer?, vetoFormat: string?, vetoRounds: table[]}?
function MatchSummary.preProcessMapVeto(mapVetoes, options)
	if Logic.isEmpty(mapVetoes) then
		return
	end

	options = options or {}
	local mapInputToDisplay = function(map)
		if Logic.isEmpty(map) then
			return {name = options.emptyMapDisplay or TBD}
		end
		if options.game then
			return {name = map, link = map .. '/' .. options.game}
		end
		return {name = map, link = map}
	end

	return {
		firstVeto = tonumber(mapVetoes[1].vetostart),
		vetoFormat = mapVetoes[1].format,
		vetoRounds = Array.map(mapVetoes, function(vetoRound)
			return {
				type = vetoRound.type,
				map1 = mapInputToDisplay(vetoRound.team1 or vetoRound.decider),
				map2 = mapInputToDisplay(vetoRound.team2),
			}
		end)
	}
end

---@param games table[]
---@param maxNumberOfBans integer
---@return {[1]: string[], [2]: string[], start: integer?}[]
function MatchSummary.buildCharacterBanData(games, maxNumberOfBans)
	return Array.map(games, function(game)
		local extradata = game.extradata or {}
		return {
			MatchSummary.buildCharacterList(extradata, 'team1ban', maxNumberOfBans),
			MatchSummary.buildCharacterList(extradata, 'team2ban', maxNumberOfBans),
			start = extradata.banstart,
		}
	end)
end

---@param data table
---@param prefix string
---@param maxNumberOfCharacters integer
---@return string[]
function MatchSummary.buildCharacterList(data, prefix, maxNumberOfCharacters)
	return Array.map(Array.range(1, maxNumberOfCharacters), function(index)
		return data[prefix .. index]
	end)
end

return MatchSummary
