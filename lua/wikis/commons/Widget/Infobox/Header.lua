---
-- @Liquipedia
-- page=Module:Widget/Infobox/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class InfoboxHeaderProps
---@field image string?
---@field imageDark string?
---@field imageDefault string?
---@field imageDefaultDark string?
---@field size string|number?
---@field imageText Renderable?
---@field name Renderable?
---@field subHeader Renderable?

local Header = {}
Header.defaultProps = {
	name = mw.title.getCurrentTitle().text,
}

---@param props InfoboxHeaderProps
---@return VNode[]
function Header.render(props)
	if props.image then
		mw.ext.SearchEngineOptimization.metaimage(props.image)
	end

	return WidgetUtil.collect(
		Header._name(props),
		Header._subHeader(props.subHeader),
		Header._image(
			props.image,
			props.imageDark,
			props.imageDefault,
			props.imageDefaultDark,
			props.size,
			props.imageText
		)
	)
end

---@param props InfoboxHeaderProps
---@return VNode
function Header._name(props)
	return Div{children = {Div{
		classes = {'infobox-header', 'wiki-backgroundcolor-light'},
		children = {
			Header._createInfoboxButtons(),
			props.name,
		}
	}}}
end

---@param subHeader Renderable?
---@return VNode?
function Header._subHeader(subHeader)
	if not subHeader then
		return nil
	end
	return Div{
		children = {
			Div{
				classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'},
				children = {subHeader}
			}
		}
	}
end

---@param fileName string?
---@param fileNameDark string?
---@param default string?
---@param defaultDark string?
---@param size number|string|nil
---@param imageText Renderable?
---@return VNode?
function Header._image(fileName, fileNameDark, default, defaultDark, size, imageText)
	if Logic.isEmpty(fileName) and Logic.isEmpty(default) then
		return nil
	end

	local imageName = fileName or default
	---@cast imageName -nil
	local infoboxImage = Header._makeSizedImage(imageName, size, 'lightmode')

	imageName = fileNameDark or fileName or defaultDark or default
	---@cast imageName -nil
	local infoboxImageDark = Header._makeSizedImage(imageName, size, 'darkmode')

	local imageTextNode = Header._makeImageText(imageText)

	return Div{
		classes = {'infobox-image-wrapper'},
		children = {infoboxImage, infoboxImageDark, imageTextNode},
	}
end

---@param imageName string
---@param size number|string|nil
---@param mode string
---@return VNode
function Header._makeSizedImage(imageName, size, mode)
	local fixedSize = false

	-- Number (interpret as pixels)
	size = size or ''
	if tonumber(size) then
		size = tonumber(size) .. 'px'
		fixedSize = true
	-- Percentage (interpret as scaling)
	elseif size:find('%%') then
		local scale = size:gsub('%%', '')
		local scaleNumber = tonumber(scale)
		if scaleNumber then
			size = 'frameless|upright=' .. (scaleNumber / 100)
			fixedSize = true
		end
	-- Default
	else
		size = '600px'
	end

	return Div{
		classes = {'infobox-image ' .. mode, fixedSize and 'infobox-fixed-size-image' or nil},
		children = {'[[File:' .. imageName .. '|center|' .. size .. ']]'},
	}
end

---@return VNode
function Header._createInfoboxButtons()
	local rootFrame
	local currentFrame = mw.getCurrentFrame()
	while currentFrame ~= nil do
		rootFrame = currentFrame
		currentFrame = currentFrame:getParent()
	end

	local moduleTitle = rootFrame:getTitle()

	-- Quick edit link
	local editLink = {
		mw.text.nowiki('['),
		Link{
			link = mw.site.server .. tostring(
				mw.uri.localUrl( mw.title.getCurrentTitle().prefixedText, 'action=edit&section=0' )
			),
			linktype = 'external',
			children = 'e',
		},
		mw.text.nowiki(']')
	}

	-- Quick help link (links to template)
	if not mw.title.new(moduleTitle).exists then
		moduleTitle = 'lpcommons:'.. moduleTitle
	end
	local helpLink = {
		mw.text.nowiki('['),
		Link{link = moduleTitle, children = 'h'},
		mw.text.nowiki(']')
	}

	return Html.Span{
		classes = {'infobox-buttons', 'navigation-not-searchable'},
		children = WidgetUtil.collect(editLink, helpLink)
	}
end

---@param text Renderable?
---@return VNode?
function Header._makeImageText(text)
	if not text then
		return
	end

	return Div{classes = {'infobox-image-text'}, children = {text}}
end

return Component.component(Header.render, Header.defaultProps)
