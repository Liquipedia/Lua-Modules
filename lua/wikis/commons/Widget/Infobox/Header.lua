---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class HeaderWidget: Widget
---@operator call(table): HeaderWidget
local Header = Class.new(Widget)
Header.defaultProps = {
	name = mw.title.getCurrentTitle().text,
}

function Header:render()
	if self.props.image then
		mw.ext.SearchEngineOptimization.metaimage(self.props.image)
	end

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_name(),
			self:_subHeader(),
			self:_image(
				self.props.image,
				self.props.imageDark,
				self.props.imageDefault,
				self.props.imageDefaultDark,
				self.props.size,
				self.props.imageText
			)
		)
	}
end

---@return Widget
function Header:_name()
	return Div{children = {Div{
		classes = {'infobox-header', 'wiki-backgroundcolor-light'},
		children = {
			self:_createInfoboxButtons(),
			self.props.name,
		}
	}}}
end

---@return Widget?
function Header:_subHeader()
	if not self.props.subHeader then
		return nil
	end
	return Div{
		children = {
			Div{
				classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'},
				children = {self.props.subHeader}
			}
		}
	}
end

---@param fileName string?
---@param fileNameDark string?
---@param default string?
---@param defaultDark string?
---@param size number|string|nil
---@param imageText string?
---@return Html?
function Header:_image(fileName, fileNameDark, default, defaultDark, size, imageText)
	if Logic.isEmpty(fileName) and Logic.isEmpty(default) then
		return nil
	end

	local imageName = fileName or default
	---@cast imageName -nil
	local infoboxImage = Header:_makeSizedImage(imageName, size, 'lightmode')

	imageName = fileNameDark or fileName or defaultDark or default
	---@cast imageName -nil
	local infoboxImageDark = Header:_makeSizedImage(imageName, size, 'darkmode')

	local imageTextNode = Header:_makeImageText(imageText)

	return Div{
		classes = {'infobox-image-wrapper'},
		children = {infoboxImage, infoboxImageDark, imageTextNode},
	}
end

---@param imageName string
---@param size number|string|nil
---@param mode string
---@return Html
function Header:_makeSizedImage(imageName, size, mode)
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

---@return Widget
function Header:_createInfoboxButtons()
	local rootFrame
	local currentFrame = mw.getCurrentFrame()
	while currentFrame ~= nil do
		rootFrame = currentFrame
		currentFrame = currentFrame:getParent()
	end

	local moduleTitle = rootFrame:getTitle()

	-- Quick edit link
	local editLink =
		mw.text.nowiki('[') .. '[' .. mw.site.server ..
		tostring(mw.uri.localUrl( mw.title.getCurrentTitle().prefixedText, 'action=edit&section=0' )) ..
		' e]' .. mw.text.nowiki(']')

	-- Quick help link (links to template)
	if not mw.title.new(moduleTitle).exists then
		moduleTitle = 'lpcommons:'.. moduleTitle
	end
	local helpLink = mw.text.nowiki('[') .. '[[' .. moduleTitle .. '|h]]' .. mw.text.nowiki(']')

	return HtmlWidgets.Span{
		classes = {'infobox-buttons', 'navigation-not-searchable'},
		children = {editLink, helpLink}
	}
end

---@param text string?
---@return Widget?
function Header:_makeImageText(text)
	if not text then
		return
	end

	return Div{classes = {'infobox-image-text'}, children = {text}}
end

return Header
