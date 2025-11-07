---
-- @Liquipedia
-- page=Module:Widget/ExternalMedia/Link
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NON_BREAKING_SPACE = '&nbsp;'

---@class ExternalMediaLinkDisplay: Widget
---@operator call(table): ExternalMediaLinkDisplay
---@field props {data: externalmedialink, showUsUk: boolean?}
local ExternalMediaLinkDisplay = Class.new(Widget)

function ExternalMediaLinkDisplay:render()
	local data = self.props.data
	return Array.interleave(WidgetUtil.collect(
		data.date .. NON_BREAKING_SPACE .. '|',
		self:_renderLanguage(),
		self:_renderTitle(),
		self:_renderAuthors(),
		self:_renderPublisher(),
		self:_renderTranslation()
	), NON_BREAKING_SPACE)
end

---@private
---@return string?
function ExternalMediaLinkDisplay:_renderLanguage()
	local data = self.props.data
	if Logic.isNotEmpty(data.language) and data.language ~= 'en' and (data.language ~= 'usuk' or self.props.showUsUk) then
		return Flags.Icon{flag = data.language, shouldLink = false}
	end
end

---@private
---@return Widget|(string|Widget)[]
function ExternalMediaLinkDisplay:_renderTitle()
	local data = self.props.data
	return WidgetUtil.collect(
		HtmlWidgets.Span{
			classes = {'plainlinks'},
			css = {['font-style'] = Logic.isNotEmpty(data.title) and 'italic' or nil},
			children = Link{
				link = data.link,
				linktype = 'external',
				children = Logic.emptyOr(mw.text.nowiki(data.title), data.link),
			}
		},
		Logic.isNotEmpty(data.translatedtitle) and (
			mw.text.nowiki('[') .. data.translatedtitle .. mw.text.nowiki(']')
		) or nil
	)
end

---@private
---@return string[]?
function ExternalMediaLinkDisplay:_renderAuthors()
	local data = self.props.data

	---@type {pageName: string, displayName: string}[]
	local authors = Array.mapIndexes(function (index)
		return Logic.nilIfEmpty{
			pageName = data.authors['author' .. index],
			displayName = data.authors['author' .. index .. 'dn']
		}
	end)

	if Logic.isEmpty(authors) then
		return
	end

	return {
		'by',
		mw.text.listToText(
			Array.map(authors, function (author)
				return Page.makeInternalLink(author.displayName, author.pageName)
			end),
			',' .. NON_BREAKING_SPACE,
			NON_BREAKING_SPACE .. 'and' .. NON_BREAKING_SPACE
		)
	}
end

---@private
---@return (string|Widget)[]?
function ExternalMediaLinkDisplay:_renderPublisher()
	local data = self.props.data
	if Logic.isEmpty(data.publisher) then
		return
	end
	return {
		'of',
		Link{link = data.publisher}
	}
end

---@private
---@return (string|Widget)[]?
function ExternalMediaLinkDisplay:_renderEvent()
	local extradata = (self.props.data.extradata or {})
	if Logic.isEmpty(extradata.event) then
		return
	end
	return {
		'at',
		Link{
			link = Logic.emptyOr(extradata.event_link, extradata.event),
			children = extradata.event
		}
	}
end

---@private
---@return string?
function ExternalMediaLinkDisplay:_renderTranslation()
	local extradata = (self.props.data.extradata or {})
	local translation = extradata.translation
	local translator = extradata.translator
	if Logic.isEmpty(translation) then
		return
	end
	return '(trans. ' ..
		Flags.Icon{flag = translation, shouldLink = false} ..
		(Logic.isNotEmpty(translator) and (
			NON_BREAKING_SPACE .. 'by' .. NON_BREAKING_SPACE .. translator
		) or '') ..
		')'
end

return ExternalMediaLinkDisplay
