---
-- @Liquipedia
-- page=Module:StreamPage/Faction
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
local FnUtil = Lua.import('Module:FnUtil')
local Image = Lua.import('Module:Image')
local Json = Lua.import('Module:Json')
local Links = Lua.import('Module:Links')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local MatchGroup = Lua.import('Module:MatchGroup')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local Tabs = Lua.import('Module:Tabs')
local Table = Lua.import('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TBD = Abbreviation.make{title = 'To be determined (or to be decided)', text = 'TBD'}

---@class FactionStreamPage: BaseStreamPage
---@operator call(table): FactionStreamPage
local FactionStreamPage = Class.new(BaseStreamPage)

---@param frame Frame
---@return Widget?
function FactionStreamPage.run(frame)
	local args = Arguments.getArgs(frame)
	args.suppressBottomContent = true
	local factionStreamPage = FactionStreamPage(args)
	return factionStreamPage:create()
end

---@return string|Widget?
function FactionStreamPage:render()
	return Tabs.dynamic{
		name1 = 'Players',
		content1 = self:renderPlayerInformation(),
		name2 = 'Head to Head',
		content2 = self:createBottomContent(),
		name3 = 'Tournament Stage',
		content3 = self:renderTournamentInformation()
	}
end

---@protected
---@return Widget
function FactionStreamPage:renderPlayerInformation()
	return HtmlWidgets.Div{
		classes = {'match-bm-players-wrapper'},
		css = {width = '100%'},
		children = Array.map(self.matches[1].opponents, FactionStreamPage._opponentDisplay)
	}
end

---@private
---@param opponent standardOpponent
---@return Widget
function FactionStreamPage._opponentDisplay(opponent)
	return HtmlWidgets.Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'match-bm-players-team-header'},
				children = OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'icon'}
			},
			Array.map(opponent.players, FnUtil.curry(FactionStreamPage._playerDisplay, opponent.type))
		)
	}
end

---@param opponentType OpponentType
---@param player standardPlayer
---@return Widget
function FactionStreamPage._playerDisplay(opponentType, player)
	local lpdbData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. (Page.pageifyLink(player.pageName) or '') .. ']]',
		limit = 1
	})[1] or {}

	local image = Logic.nilIfEmpty(lpdbData.image) or 'Blank Player Image.png'
	local imageDisplay = Image.display(image, nil, {class = 'img-fluid', size = '600px'})

	local nameDisplay = opponentType ~= Opponent.solo and PlayerDisplay.InlinePlayer{
		player = player
	} or nil

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
					Opponent.typeIsParty(opponentType) and Logic.isNotEmpty(lpdbData.team) and HtmlWidgets.Span{children = {
						HtmlWidgets.B{children = 'Team: '},
						OpponentDisplay.InlineTeamContainer{
							template = lpdbData.team,
							style = 'standard'
						}
					}} or nil,
					not DateExt.isDefaultTimestamp(lpdbData.birthdate) and HtmlWidgets.Span{children = {
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

function FactionStreamPage:renderTournamentInformation()
	local match = self.matches[1]
	return HtmlWidgets.Div{
		children = WidgetUtil.collect(
			self:_mapPool(),
			MatchGroup.MatchGroupById{id = match.bracketId}
		)
	}
end

---@private
---@return Widget?
function FactionStreamPage:_mapPool()
	local match = self.matches[1]

	local maps = Json.parse(mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. match.parent .. ']]',
		query = 'maps',
		limit = 1,
	})[1].maps)

	if Logic.isEmpty(maps) then
		return
	end

	local race1 = ((match.opponents[1].players)[1] or {}).faction --[[ @as string ]]
	local race2 = ((match.opponents[2].players)[1] or {}).faction --[[ @as string ]]

	local skipMapWinRate = not Array.all(match.opponents, function (opponent) return opponent.type == Opponent.solo end)
		or not Table.includes(Faction.coreFactions or {}, race1)
		or not Table.includes(Faction.coreFactions or {}, race2)

	local currentMap = self:_getCurrentMap()
	local matchup = skipMapWinRate and '' or (race1 .. race2)

	--- sc/sc2/wc/sg use `displayname` while aoe uses `name`
	---@param map {link: string, displayname: string?, name: string?}
	---@return Widget
	local createMapCell = function(map)
		return TableWidgets.Cell{
			classes = {map.link == currentMap and 'tournament-highlighted-bg' or nil},
			children = Link{link = map.link, children = map.displayname or map.name},
		}
	end

	--- sc/sc2/wc/sg use `displayname` while aoe uses `name`
	---@param map {link: string, displayname: string?, name: string?}
	---@return Widget
	local createMapWinRateCell = function(map)
		return TableWidgets.Cell{
			classes = {map.link == currentMap and 'tournament-highlighted-bg' or nil},
			children = FactionStreamPage._queryMapWinrate(map.link, matchup),
		}
	end

	return {
		TableWidgets.Table{
			columns = {
				{align = 'center'},
				not skipMapWinRate and {align = 'center'} or nil,
			},
			title = 'Map Pool',
			children = TableWidgets.TableBody{
				children = {
					TableWidgets.Row{
						children = WidgetUtil.collect(
							not skipMapWinRate and TableWidgets.CellHeader{children = 'Map'} or nil,
							Array.map(maps, createMapCell)
						)
					},
					not skipMapWinRate and TableWidgets.Row{
						children = WidgetUtil.collect(
							TableWidgets.CellHeader{children = race1:upper() .. 'v' .. race2:upper()},
							Array.map(maps, createMapWinRateCell)
						)
					} or nil
				}
			}
		},
		HtmlWidgets.Br{}
	}
end

---@param map string
---@param matchup string
---@return string?
function FactionStreamPage._queryMapWinrate(map, matchup)
	local conditions = '[[pagename::' .. string.gsub(map, ' ', '_') .. ']] AND [[type::map_winrates]]'
	local LPDBoutput = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions,
		query = 'extradata',
	})[1]

	if type(LPDBoutput) ~= 'table' or Logic.isEmpty(LPDBoutput) then
		return TBD
	end
	local data = (LPDBoutput.extradata or {})[matchup]
	if Logic.isEmpty(data) or data == '-' then
		return TBD
	end
	return MathUtil.formatPercentage(data)
end

---@private
---@return string?
function FactionStreamPage:_getCurrentMap()
	local games = self.matches[1].games
	for _, game in ipairs(games) do
		if Logic.isEmpty(game.winner) then
			return game.map
		end
	end
end

return FactionStreamPage
