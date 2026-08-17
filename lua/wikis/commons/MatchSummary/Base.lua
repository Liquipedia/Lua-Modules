---
-- @Liquipedia
-- page=Module:MatchSummary/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local Map = Lua.import('Module:Map')
local Table = Lua.import('Module:Table')
local VodLink = Lua.import('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Links = Lua.import('Module:Links')
local Html = Lua.import('Module:Widget/Html')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local MatchButtonBar = Lua.import('Module:Widget/Match/ButtonBar')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MATCH_LINK_PRIORITY = Lua.import('Module:Links/MatchPriorityGroups', {loadData = true})
local TBD = Abbreviation.make{text = 'TBD', title = 'To Be Determined'}

---@class CustomMatchSummaryInterface
---@field createBody? fun(match: MatchGroupUtilMatch): Renderable|Renderable[] @deprecated
---@field createGames? fun(match: MatchGroupUtilMatch): Renderable|Renderable[]
---@field createGame? fun(date: string, game: table, gameIndex: integer): Renderable|Renderable[]
---@field createFooter? fun(match: MatchGroupUtilMatch): Renderable|Renderable[]

---@class MatchSummary
local MatchSummary = {}

---Default header function
---@param match MatchGroupUtilMatch
---@param options {teamStyle: teamStyle?}?
---@return VNode
function MatchSummary.createHeader(match, options)
	options = options or {}

	return Html.Fragment{
		children = {
			MatchCountdown{
				match = match,
			},
			MatchHeader{
				match = match,
				teamStyle = options.teamStyle or 'dynamic',
			}
		}
	}
end

-- Default body function
---@param match MatchGroupUtilMatch
---@param createGames fun(match: MatchGroupUtilMatch): Renderable|Renderable[]?
---@param createGame fun(date: string, game: table, gameIndex: integer): Renderable|Renderable[]
---@param options {maxBans: integer?}?
---@return Renderable[]
function MatchSummary.createDefaultBody(match, createGames, createGame, options)
	options = options or {}

	local characterBansData = MatchSummary.buildCharacterBanData(match.games, options.maxBans or 0)

	return WidgetUtil.collect(
		createGames and createGames(match) or Array.map(match.games, FnUtil.curry(createGame, match.date)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---Default footer function
---@param match MatchGroupUtilMatch
---@return Renderable
function MatchSummary.createDefaultFooter(match)
	return MatchSummaryWidgets.Footer{children = WidgetUtil.collect(
		MatchSummary.makeVodDisplay(match.vod, match.games),
		MatchSummary.makeLinksDisplay(match.links)
	)}
end

---@param matchVod string?
---@param games MatchGroupUtilGame[]
---@return Renderable[]
function MatchSummary.makeVodDisplay(matchVod, games)
	local vods = {}
	if matchVod then
		table.insert(vods, VodLink.display{
			vod = matchVod,
		})
	end

	Array.forEach(games, function(game, gameIndex)
		if not game.vod then
			return
		end
		table.insert(vods, VodLink.display{
			gamenum = gameIndex,
			vod = game.vod,
		})
	end)

	return vods
end

---@param link string
---@param icon string
---@param iconDark string?
---@param text string
---@param class string?
---@return string?
function MatchSummary.makeLinkDisplay(link, icon, iconDark, text, class)
	return Image.display(icon, iconDark, {
		link = link, size = '32px', caption = text, alt = link, class = class
	})
end

---@param links table<string, string|table>
---@return Renderable[]
function MatchSummary.makeLinksDisplay(links)
	local linkDisplays = {}

	local makeAndSaveLink = function(link, icon, iconDark, text, class)
		local display = MatchSummary.makeLinkDisplay(link, icon, iconDark, text, class)
		table.insert(linkDisplays, display)
	end

	local processLink = function(linkType, link)
		local currentLinkData = Links.getMatchIconData(linkType)
		if not currentLinkData then
			mw.log('Unknown link: ' .. linkType)
		elseif type(link) == 'table' then
			for gameIdx, gameLink in Table.iter.spairs(link) do
				local newText = currentLinkData.text .. ' on Game ' .. gameIdx
				makeAndSaveLink(gameLink, currentLinkData.icon, currentLinkData.iconDark, newText)
			end
		else
			-- Temporary during MW/LH Migrations
			local class
			if linkType == 'headtohead_lh' then
				class = 'hide-when-mediawiki'
			elseif linkType == 'headtohead' then
				class = 'hide-when-lighthouse'
			end
			makeAndSaveLink(link, currentLinkData.icon, currentLinkData.iconDark, currentLinkData.text, class)
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

	return linkDisplays
end

---Default createMatch function for usage in Custom MatchSummary
---@param matchData MatchGroupUtilMatch?
---@param CustomMatchSummary CustomMatchSummaryInterface
---@param options {teamStyle: teamStyle?, noScore: boolean?, maxBans: integer?}?
---@return VNode?
function MatchSummary.createMatch(matchData, CustomMatchSummary, options)
	if not matchData then
		return
	end

	local createBody = CustomMatchSummary.createBody or MatchSummary.createDefaultBody
	local createFooter = CustomMatchSummary.createFooter or MatchSummary.createDefaultFooter

	return Html.Fragment{children = WidgetUtil.collect(
		MatchSummary.createHeader(matchData, options),
		MatchSummaryWidgets.Body{
			children = WidgetUtil.collect(
				createBody(matchData, CustomMatchSummary.createGames, CustomMatchSummary.createGame, options),
				Html.Fragment{
					children = {
						MatchSummaryWidgets.Casters{casters = matchData.extradata.casters},
						MatchSummaryWidgets.MatchComment{
							children = WidgetUtil.collect(
								matchData.comment,
								DisplayHelper.createSubstitutesComment(matchData)
							)
						}
					}
				},
				createFooter(matchData)
			)
		},
		MatchButtonBar{match = matchData, showVods = false, variant = 'primary'} -- Vods are in the footer currently
	)}
end

---Default getByMatchId function for usage in Custom MatchSummary
---@param CustomMatchSummary CustomMatchSummaryInterface
---@param args table
---@param options {teamStyle:teamStyle?, width: (fun(match: MatchGroupUtilMatch):string?)|string?,
---noScore:boolean?, maxBans: integer?}?
---@return VNode
function MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
	assert(
		(
			type(CustomMatchSummary.createBody) == 'function' or
			type(CustomMatchSummary.createGame) == 'function' or
			type(CustomMatchSummary.createGames) == 'function'
		),
		'createBody or createGame or createGames must be implemented in Module:MatchSummary'
	)

	options = options or {}

	local match, bracketResetMatch = MatchGroupUtil.fetchMatchForBracketDisplay(
		args.bracketId, args.matchId)

	---@type (fun(match: MatchGroupUtilMatch):string?)|string|integer?
	local width = args.width or options.width or (args.config or {}).width
	if type(width) == 'function' then
		width = width(match)
	elseif Logic.isNumeric(width) then
		width = width .. 'px'
	end

	return MatchSummaryWidgets.Container{
		classes = args.classes,
		width = width,
		createMatch = function(matchData)
			return MatchSummary.createMatch(matchData, CustomMatchSummary, options)
		end,
		match = match,
		resetMatch = bracketResetMatch,
	}
end

---@param mapVetoes table
---@param options {game: string?, emptyMapDisplay: string?, useLpdb: boolean?}?
---@return MapVetoProps?
function MatchSummary.preProcessMapVeto(mapVetoes, options)
	if Logic.isEmpty(mapVetoes) then
		return
	end

	options = options or {}

	---@param map string?
	---@return {name: string, link: string?}
	local mapInputToDisplay = FnUtil.memoize(function(map)
		if Logic.isEmpty(map) then
			return {name = options.emptyMapDisplay or TBD}
		end
		---@cast map -nil
		if options.useLpdb then
			local mapData = Map.getMapByName(map)
			if mapData then
				return {name = mapData.displayName, link = mapData.pageName}
			end
			return {name = map}
		end
		if options.game then
			return {name = map, link = map .. '/' .. options.game}
		end
		return {name = map, link = map}
	end)

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
	return Array.mapRange(1, maxNumberOfCharacters, function(index)
		return data[prefix .. index]
	end)
end

return MatchSummary
