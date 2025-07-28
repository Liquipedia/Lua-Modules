---
-- @Liquipedia
-- page=Module:Widget/Match/VodsDropdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local VodLink = Lua.import('Module:VodLink')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')

---@class VodsDropdown: Widget
---@operator call(table): VodsDropdown
local VodsDropdown = Class.new(Widget)
VodsDropdown.defaultProps = {
	matchIsLive = true,
}

---@return Widget?
function VodsDropdown:render()
	local match = self.props.match
	if not match then
		return nil
	end

	local makeVod = function(vod, type, number)
		if not vod then
			return
		end
		return {
			vod = vod,
			type = type,
			number = number,
		}
	end

	local gameVods = Array.map(match.games, function(game, index)
		if Logic.isEmpty(game.vod) then
			return nil
		end
		return makeVod(game.vod, 'game', index)
	end)
	local matchVod = makeVod(match.vod, 'match', 1)
	-- TODO match2vod is sometimes present (countrestrike?)

	---@param vod table
	---@return Widget?
	local makeVodButton = function(vod, showText)
		return Button{
			linktype = 'external',
			title = VodLink.getTitle(vod.type == 'game' and vod.number or nil),
			variant = 'tertiary',
			link = vod,
			size = 'sm',
			classes = {'vodlink'},
			children = {
				ImageIcon{imageLight = VodLink.getIcon(vod.number)},
				showText and HtmlWidgets.Span{
					classes = {'match-button-cta-text'},
					children = 'Watch VOD',
				} or nil,
			},
		}
	end

	if #gameVods == 0 and not matchVod then
		return nil
	elseif matchVod then
		return makeVodButton(matchVod)
	elseif #gameVods == 1 then
		return makeVodButton(gameVods[1])
	end

	-- TODO: Make Dropdown button, toggle and row
	return Array.map(processedStreams, function(stream)
		return MatchStream{
			platform = stream.platform,
			stream = stream.stream,
			matchIsLive = self.props.matchIsLive,
		}
	end)
end

return VodsDropdown
