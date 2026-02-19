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

local DataTable = Lua.import('Module:Widget/Basic/DataTable')
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
	})[1] or {}

	local image  = lpdbData.image
	if String.isEmpty(image) then
		image = Logic.emptyOr((lpdbData.extradata or {}).image, 'Blank Player Image.png') --[[@as string]]
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

---@private
---@return Html
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

	local race1 = ((match.opponents[1].players)[1] or {}).faction --[[ @as string ]]
	local race2 = ((match.opponents[2].players)[1] or {}).faction --[[ @as string ]]

	local skipMapWinRate = not Array.all(match.opponents, function (opponent) return opponent.type == Opponent.solo end)
		or not race1
		or not race2
		or race1 == Faction.defaultFaction
		or race1 == RANDOM_RACE
		or race2 == Faction.defaultFaction
		or race1 ~= race2

	local currentMap = self:_getCurrentMap()
	local matchup = skipMapWinRate and '' or race1 .. race2

	---@param map 'TBA'|{link: string, displayname: string}
	---@return Widget
	local function createMapRow(map)
		if map == 'TBA' then
			return HtmlWidgets.Tr{
				classes = {'stats-row'},
				children = HtmlWidgets.Td{
					attributes = {colspan = 2},
					children = HtmlWidgets.Span{
						css = {
							['text-align'] = 'center',
							['font-style'] = 'italic',
						},
						children = 'To be announced'
					}
				}
			}
		end
		return HtmlWidgets.Tr{
			classes = {
				'stats-row',
				map.link == currentMap and 'tournament-highlighted-bg' or nil
			},
			children = WidgetUtil.collect(
				HtmlWidgets.Td{children = Link{link = map.link, children = map.displayname}},
				not skipMapWinRate and HtmlWidgets.Td{
					children = StarcraftStreamPage._queryMapWinrate(map.link, matchup)
				} or nil
			),
		}
	end

	return DataTable{
		tableCss = {
			['text-align'] = 'center',
			margin = '0 0 10px 0',
		},
		children = WidgetUtil.collect(
			HtmlWidgets.Tr{
				classes = {'wiki-color-dark', 'wiki-backgroundcolor-light'},
				css = {
					['font-size'] = '130%',
					padding = '5px 10px',
				},
				children = {HtmlWidgets.Th{
					attributes = {colspan = 2},
					css = {padding = '5px'},
					children = 'Map Pool'
				}}
			},
			not skipMapWinRate and HtmlWidgets.Tr{children = {
				HtmlWidgets.Th{children = 'Map'},
				HtmlWidgets.Th{children = {
					race1:upper(),
					'v',
					race2:upper()
				}}
			}} or nil,
			Array.map(maps, createMapRow)
		)
	}
end

---@param map string
---@param matchup string
---@return string?
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

---@private
---@return string?
function StarcraftStreamPage:_getCurrentMap()
	local games = self.matches[1].games
	for _, game in ipairs(games) do
		if Logic.isEmpty(game.winner) then
			return game.map
		end
	end
end

return StarcraftStreamPage
