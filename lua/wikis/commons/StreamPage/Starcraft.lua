---
-- @Liquipedia
-- page=Module:StreamPage/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local BaseStreamPage = Lua.import('Module:StreamPage/Base')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Image = Lua.import('Module:Image')
local Json = Lua.import('Module:Json')
local Links = Lua.import('Module:Links')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local RANDOM_RACE = 'r'
local TBD = Abbreviation.make{title = 'To be determined (or to be decided)', text = 'TBD'}

---@class StarcraftStreamPage: BaseStreamPage
---@operator call(table): StarcraftStreamPage
local StarcraftStreamPage = Class.new(BaseStreamPage)

---@param frame Frame
---@return Widget?
function StarcraftStreamPage.run(frame)
	local args = Arguments.getArgs(frame)
	return StarcraftStreamPage(args):create()
end

---@return Widget|Widget[]?
function StarcraftStreamPage:render()
	return {
		HtmlWidgets.H3{children = 'Player Information'},
		self:renderPlayerInformation(),
		self:_mapPool()
	}
end

---@protected
---@return Widget
function StarcraftStreamPage:renderPlayerInformation()
	return HtmlWidgets.Div{
		classes = {'match-bm-players-wrapper'},
		css = {width = '100%'},
		children = Array.map(self.matches[1].opponents, StarcraftStreamPage._teamDisplay)
	}
end

---@private
---@param opponent standardOpponent
---@return Widget
function StarcraftStreamPage._teamDisplay(opponent)
	return HtmlWidgets.Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'match-bm-players-team-header'},
				children = OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'icon'}
			},
			Array.map(opponent.players, StarcraftStreamPage._playerDisplay)
		)
	}
end

---@param player standardPlayer
---@return Widget
function StarcraftStreamPage._playerDisplay(player)
	local lpdbData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. (Page.pageifyLink(player.pageName) or '') .. ']]',
		limit = 1
	})[1]

	local playerData = {}
	local image
	if lpdbData then
		playerData = lpdbData
		image = playerData.image
		if String.isEmpty(image) then
			image = (playerData.extradata or {}).image
		end
	end
	if String.isEmpty(image) then
		image = 'Blank Player Image.png'
	end
	local imageDisplay = Image.display(image, nil, {class = 'img-fluid', size = '600px'})

	local nameDisplay = PlayerDisplay.InlinePlayer{
		player = player
	}

	return HtmlWidgets.Div{
		classes = {'match-bm-players-player', 'match-bm-players-player--col-2'},
		children = {
			imageDisplay,
			HtmlWidgets.Div{
				css = {
					display = 'flex',
					['flex-direction'] = 'column',
				},
				children = WidgetUtil.collect(
					nameDisplay,
					lpdbData.name and HtmlWidgets.Span{children = {
						HtmlWidgets.B{children = 'Name: '},
						lpdbData.name
					}} or nil,
					lpdbData.birthdate ~= DateExt.defaultDate and HtmlWidgets.Span{children = {
						HtmlWidgets.B{children = 'Birth: '},
						mw.getContentLanguage():formatDate('F j, Y', lpdbData.birthdate),
						' (' .. DateExt.calculateAge(DateExt.getCurrentTimestamp(), lpdbData.birthdate) .. ')'
					}} or nil,
					(tonumber(lpdbData.earnings) or 0) > 0 and HtmlWidgets.Span{children = {
						HtmlWidgets.B{children = 'Earnings: '},
						Currency.display('usd', lpdbData.earnings, {formatValue = true})
					}} or nil,
					HtmlWidgets.Span{children = Array.interleave(
						Array.extractValues(Table.map(lpdbData.links or {}, function(key, link)
							return key, Link{
								link = link,
								children = Links.makeIcon(Links.removeAppendedNumber(key), 21),
								linktype = 'external'
							}
						end), Table.iter.spairs),
						' '
					)}
				)
			}
		}
	}
end

function StarcraftStreamPage:_mapPool()
	local match = self.matches[1]

	local maps = Logic.emptyOr(
		Json.parse(mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = '[[pagename::' .. match.parent .. ']]',
			query = 'maps',
			limit = 1,
		})[1].maps),
		{'TBA'}
	) --[[ @as any[] ]]

	local race1 = ((match.opponents[1].players)[1] or {}).faction
	local race2 = ((match.opponents[2].players)[1] or {}).faction

	local skipMapWinRate = match.opponents[1].type ~= Opponent.solo
		or not race1
		or not race2
		or match.opponents[2].type ~= Opponent.solo
		or race1 == Faction.defaultFaction
		or race1 == RANDOM_RACE
		or race2 == Faction.defaultFaction
		or race1 ~= race2

	local mapTable = mw.html.create('table')
		:addClass('wikitable')
		:css('text-align', 'center')
		:css('margin', '0 0 10px 0')
		:css('width', '100%')
		mapTable:tag('tr')
			:addClass('wiki-color-dark wiki-backgroundcolor-light')
			:css('font-size', '130%')
			:css('padding', '5px 10px')
			:tag('th')
				:attr('colspan', '2')
				:css('padding', '5px')
				:wikitext('Map Pool')

	if not skipMapWinRate then
		---@cast race1 -nil
		---@cast race2 -nil
		mapTable:tag('tr')
			:tag('th'):wikitext('Map')
			:tag('th'):wikitext(string.upper(race1) .. 'v' .. string.upper(race2))
	end

	local currentMap = self:_getCurrentMap()
	local matchup = skipMapWinRate and '' or race1 .. race2

	for _, map in ipairs(maps) do
		local mapRow = mapTable:tag('tr')
			:addClass('stats-row')

		if map == 'TBA' then
			mapRow:tag('td')
				:attr('colspan', '2')
				:node(mw.html.create('span')
					:css('text-align', 'center')
					:css('font-style', 'italic')
					:wikitext('To be announced')
				)
		else
			if map.link == currentMap then
				mapRow:addClass('tournament-highlighted-bg')
			end
			mapRow:tag('td')
				:wikitext('[[' .. map.link .. '|' .. map.displayname .. ']]')
			if not skipMapWinRate then
				local winRate = StarcraftStreamPage._queryMapWinrate(map.link, matchup)
				if String.isNotEmpty(winRate) then
					mapRow:tag('td')
						:wikitext(winRate)
				end
			end
		end
	end

	return mw.html.create('div')
		:addClass('sc2-stream-page-middle-column1')
		:node(mapTable)
end

function StarcraftStreamPage._getMaps(mapsInput)
	if String.isEmpty(mapsInput) then
		return {'TBA'}
	end

	return Json.parse(mapsInput)
end

function StarcraftStreamPage._queryMapWinrate(map, matchup)
	local conditions = '[[pagename::' .. string.gsub(map, ' ', '_') .. ']] AND [[type::map_winrates]]'
	local LPDBoutput = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions,
		query = 'extradata',
	})

	if type(LPDBoutput[1]) == 'table' then
		if LPDBoutput[1]['extradata'][matchup] == '-' then
			return TBD
		else
			return math.floor(LPDBoutput[1]['extradata'][matchup]*100 + 0.5) .. '%'
		end
	else
		return TBD
	end
end

function StarcraftStreamPage:_getCurrentMap()
	local games = self.matches[1].games
	for _, game in ipairs(games) do
		if Logic.isEmpty(game.winner) then
			return game.map
		end
	end
end

return StarcraftStreamPage
