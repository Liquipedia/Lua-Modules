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
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Span = HtmlWidgets.Span

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
	---@cast gameVods table[]
	local matchVod = makeVod(match.vod, 'match', 1)
	-- TODO second vod is sometimes present (countrestrike?)

	---@param vod table
	---@return Widget?
	local makeSingleVodButton = function(vod, showText)
		local gameNumber = vod.type == 'game' and vod.number or nil
		return Button{
			linktype = 'external',
			title = VodLink.getTitle(gameNumber),
			variant = 'tertiary',
			link = vod.vod,
			size = 'sm',
			classes = {'vodlink'},
			children = {
				ImageIcon{imageLight = VodLink.getIcon(gameNumber)},
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
		return makeSingleVodButton(matchVod)
	elseif #gameVods == 1 then
		return makeSingleVodButton(gameVods[1])
	end

	---@param vodCount integer
	---@return Widget
	local vodToggleButton = function(vodCount)
		local showButton = Button{
			classes = {'general-collapsible-expand-button'},
			children = {
				ImageIcon{imageLight = VodLink.getIcon()},
				'(' .. vodCount .. ')',
				Icon{iconName = 'expand'},
			},
			size = 'sm',
			variant = 'tertiary',
		}
		local hideButton = Button{
			classes = {'general-collapsible-collapse-button'},
			children = {
				ImageIcon{imageLight = VodLink.getIcon()},
				'(' .. vodCount .. ')',
				Icon{iconName = 'hide'},
			},
			size = 'sm',
			variant = 'tertiary',
		}

		return Span{
			classes = {'general-collapsible-default-toggle'},
			css = self.props.css,
			attributes = self.props.attributes,
			children = {
				showButton,
				hideButton,
			}
		}
	end

	---@param vod table
	---@return Widget?
	local makeGameVodButton = function(vod, showText)
		local gameNumber = vod.number
		return Button{
			linktype = 'external',
			title = VodLink.getTitle(gameNumber),
			variant = 'tertiary',
			link = vod.vod,
			size = 'sm',
			classes = {'vodlink'},
			children = {
				Icon{iconName = 'vod_play'},
				HtmlWidgets.Span{
					children = showText and ('VOD ' .. gameNumber) or gameNumber,
				}
			},
		}
	end

	-- TODO: Styling
	-- TODO: Container for child elements
	return Collapsible{
		classes = {'match-vods-dropdown'},
		titleWidget = vodToggleButton(#gameVods),
		titleClasses = {'match-vods-dropdown-title'},
		shouldCollapse = true,
		children = Array.map(gameVods, function(vod)
			return makeGameVodButton(vod, #gameVods < 4)
		end),
		collapseAreaClasses = {'match-vodsdropdown-collapse-area'},
	}
end

return VodsDropdown
