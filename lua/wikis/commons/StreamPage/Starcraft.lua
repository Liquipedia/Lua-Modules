---
-- @Liquipedia
-- page=Module:StreamPage/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local BaseStreamPage = Lua.import('Module:StreamPage/Base')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Image = Lua.import('Module:Image')
local Links = Lua.import('Module:Links')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

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
		self:renderPlayerInformation()
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

return StarcraftStreamPage
