---
-- @Liquipedia
-- page=Module:StreamPage/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local BaseStreamPage = Lua.import('Module:StreamPage/Base')
local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TeamStreamPage: BaseStreamPage
---@operator call(table): TeamStreamPage
local TeamStreamPage = Class.new(BaseStreamPage)

---@param frame Frame
---@return Widget?
function TeamStreamPage.run(frame)
	local args = Arguments.getArgs(frame)
	return TeamStreamPage(args):create()
end

---@return Widget|Widget[]?
function TeamStreamPage:render()
	return {
		HtmlWidgets.H3{children = 'Player Information'},
		self:renderPlayerInformation()
	}
end

---@protected
---@return Widget
function TeamStreamPage:renderPlayerInformation()
	return HtmlWidgets.Div{
		classes = {'match-bm-players-wrapper'},
		children = Array.map(self.matches[1].opponents, TeamStreamPage._teamDisplay)
	}
end

---@private
---@param opponent standardOpponent
---@return Widget
function TeamStreamPage._teamDisplay(opponent)
	return HtmlWidgets.Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'match-bm-players-team-header'},
				children = OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'icon'}
			},
			Array.map(opponent.players, TeamStreamPage._playerDisplay)
		)
	}
end

---@param player standardPlayer
---@return Widget
function TeamStreamPage._playerDisplay(player)
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
		children = {imageDisplay, nameDisplay}
	}
end

return TeamStreamPage
