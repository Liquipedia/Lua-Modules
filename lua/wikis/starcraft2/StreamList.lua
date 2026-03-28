local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Box = Lua.import('Module:Box')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local StreamLinks = Lua.import('Module:Links/Stream')
local Table = Lua.import('Module:Table')

local HtmlWidgets = require('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local WidgetUtil = Lua.import('Module:Widget/Util')

local StreamList = {}

local DEFAULT_DEFAULT_PROVIDER = 'twitch'
local DEFAULT_DEFAULT_FLAG = 'usuk'
local COLUMN_BREAK = 5

local PROVIDERS = StreamLinks.countdownPlatformNames

---@param args table
---@return Widget[]
function StreamList.run(args)
	local defaultProvider = Logic.nilIfEmpty(args.defaultprovider) or DEFAULT_DEFAULT_PROVIDER
	local defaultFlag = Logic.nilIfEmpty(args.defaultflag) or DEFAULT_DEFAULT_FLAG

	---@param streamIndex integer
	---@return Widget?
	local makeLink = function(streamIndex)
		local stream = args['s' .. streamIndex] or args['link' .. streamIndex]
		if Logic.isEmpty(stream) then
			return
		end
		if Logic.isNotEmpty(args['link' .. streamIndex]) then
			return Link{
				link = args['link' .. streamIndex],
				children = args['display' .. streamIndex] or stream,
				linktype = 'external',
			}
		end

		local provider = string.lower(args['provider' .. streamIndex] or defaultProvider)
		assert(Table.includes(PROVIDERS, provider), 'Invalid Provider: ' .. provider)
		if provider == 'afreeca' then
			provider = 'afreecatv'
		end

		return Link{
			link = 'Special:Stream/' .. provider .. '/' .. stream,
			children = args['display' .. streamIndex] or stream,
		}
	end

	---@type {link: Widget, flag: string}[]
	local streams = Array.mapIndexes(function(streamIndex)
		local link = makeLink(streamIndex)
		if not link then
			return
		end
		return {
			link = makeLink(streamIndex),
			flag = args['flag' .. streamIndex] or defaultFlag,
		}
	end)

	return StreamList._display(streams, tonumber(args.columnbreak) or COLUMN_BREAK)
end

---@param streams {link: Widget, flag: string}[]
---@param columnBreak integer
---@return Widget|(Widget|string)[]
function StreamList._display(streams, columnBreak)
	---@type {link: Widget, flag: string}[][]
	local segments = {}
	local currentIndex = 0
	Array.forEach(streams, function(item, index)
		if index % columnBreak == 1 then
			currentIndex = currentIndex + 1
			segments[currentIndex] = {}
		end
		table.insert(segments[currentIndex], item)
	end)

	---@type (Widget|string)[]
	local parts = Array.map(segments, function(group)
		return UnorderedList{children = Array.map(group, function(data)
			return {
				Flags.Icon{flag = data.flag, shouldLink = false},
				' ',
				data.link,
			}
		end)}
	end)

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			Box._template_box_start{padding = '2em'},
			Array.interleave(parts, Box.brk{padding = '2em'}),
			Box.finish()
		)
	}
end

return Class.export(StreamList, {exports = {'run'}})
