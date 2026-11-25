---
-- @Liquipedia
-- page=Module:Widget/Infobox/Chronology
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local InlineIconAndText = Lua.import('Module:Widget/Misc/InlineIconAndText')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Title = Lua.import('Module:Widget/Infobox/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Chronology = {}
Chronology.defaultProps = {
	title = 'Chronology',
	showTitle = false,
}

---@param props {links: {previous: {link:string, text: string}?, next: {link:string, text: string}?}[],
---title: string, showTitle: boolean}
---@return Widget[]?
function Chronology.render(props)
	local links = props.links
	if Logic.isEmpty(links) then
		return
	end

	return WidgetUtil.collect(
		Logic.readBool(props.showTitle) and Title{children = props.title} or nil,
		Array.map(props.links, Chronology._createChronologyRow)
	)
end

---@param links {previous: {link:string, text: string}?, next: {link:string, text: string}?}
---@return Widget?
function Chronology._createChronologyRow(links)
	if Logic.isEmpty(links) then return end

	---@param mode 'previous'|'next'
	---@return Widget?
	local makeCell = function(mode)
		if not links[mode] then return end
		return Div{
			classes = {'infobox-cell-2', 'infobox-text-' .. (mode == 'previous' and 'left' or 'right')},
			children = InlineIconAndText{
				link = links[mode].link,
				text = links[mode].text,
				icon = IconFa{
					iconName = mode,
					link = links[mode].link,
				},
				flipped = mode ~= 'previous',
			}
		}
	end

	return Div{
		children = {
			makeCell('previous') or Div{classes = {'infobox-cell-2'}},
			makeCell('next'),
		}
	}
end

return Component.component(Chronology.render, Chronology.defaultProps)
