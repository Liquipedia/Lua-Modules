---
-- @Liquipedia
-- page=Module:Widget/ExternalMedia/Link
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NON_BREAKING_SPACE = '&nbsp;'

local ExternalMediaLinkDisplay = {}

---@param props {data: externalmedialink, showUsUk: boolean?}
---@return Renderable[]
function ExternalMediaLinkDisplay.render(props)
	local data = props.data
	return Array.interleave(WidgetUtil.collect(
		data.date .. NON_BREAKING_SPACE .. '|',
		ExternalMediaLinkDisplay._renderLanguage(data, props.showUsUk),
		ExternalMediaLinkDisplay._renderTitle(data),
		ExternalMediaLinkDisplay._renderAuthors(data),
		ExternalMediaLinkDisplay._renderPublisher(data),
		ExternalMediaLinkDisplay._renderEvent(data),
		ExternalMediaLinkDisplay._renderTranslation(data)
	), NON_BREAKING_SPACE)
end

---@private
---@param data externalmedialink
---@param showUsUk boolean?
---@return string?
function ExternalMediaLinkDisplay._renderLanguage(data, showUsUk)
	if Logic.isNotEmpty(data.language) and data.language ~= 'en' and (data.language ~= 'usuk' or showUsUk) then
		return Flags.Icon{flag = data.language, shouldLink = false}
	end
end

---@private
---@param data externalmedialink
---@return Renderable[]
function ExternalMediaLinkDisplay._renderTitle(data)
	return WidgetUtil.collect(
		Html.Span{
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
---@param data externalmedialink
---@return string[]?
function ExternalMediaLinkDisplay._renderAuthors(data)
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
---@param data externalmedialink
---@return Renderable[]?
function ExternalMediaLinkDisplay._renderPublisher(data)
	if Logic.isEmpty(data.publisher) then
		return
	end
	return {
		'of',
		Link{link = data.publisher}
	}
end

---@private
---@param data externalmedialink
---@return Renderable[]?
function ExternalMediaLinkDisplay._renderEvent(data)
	local extradata = (data.extradata or {})
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
---@param data externalmedialink
---@return string?
function ExternalMediaLinkDisplay._renderTranslation(data)
	local extradata = (data.extradata or {})
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

return Component.component(ExternalMediaLinkDisplay.render)
