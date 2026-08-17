---
-- @Liquipedia
-- page=Module:Widget/ArticleMessageBox

--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Html = Lua.import('Module:Widget/Html')
local WidgetTable = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {text: Renderable|Renderable[]?, classes: string|string[]?, imageSize: string?, image: string?,
---imageDark: string?, icon: string?, iconClasses: string|string[]?}
---@return VNode?
local function ArticleMessageBox(props)
	local text = props.text
	if Logic.isEmpty(text) then
		return
	end
	---@cast text -nil

	local image
	if Logic.isNotEmpty(props.image) then
		image = WidgetTable.Cell{
			classes = {'ambox-image'},
			children = IconImage{
				imageLight = props.image,
				imageDark = props.imageDark,
				size = props.imageSize,
			}
		}
	elseif Logic.isNotEmpty(props.icon) then
		image = WidgetTable.Cell{
			classes = WidgetUtil.collect('ambox-fa-icon', props.iconClasses),
			children = IconFa{
				iconName = props.icon,
			}
		}
	end

	return Html.Div{
		classes = WidgetUtil.collect(
			'ambox-wrapper',
			'ambox',
			'wiki-bordercolor-dark',
			'wiki-backgroundcolor-light',
			props.classes
		),
		children = WidgetTable.Table{
			classes = {'inherit-bg'},
			children = {
				WidgetTable.TableBody{children = {WidgetTable.Row{children = WidgetUtil.collect(
					image,
					WidgetTable.Cell{classes = {'ambox-text'}, children = text, nowrap = false}
				)}}}
			},
		}
	}
end

return Component.component(ArticleMessageBox, {imageSize = '40px'})
