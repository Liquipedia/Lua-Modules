local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local StreamLinks = Lua.import('Module:Links/Stream')
local Table = Lua.import('Module:Table')

local Box = Lua.import('Module:Widget/Basic/Box')
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local Widget = Lua.import('Module:Widget')

---@class StreamList: Widget
---@operator call(table): StreamList
local StreamList = Class.new(Widget)
StreamList.defaultProps = {
	defaultprovider = 'twitch',
	defaultflag = 'usuk',
	columnbreak = 5,
}

---@return Widget
function StreamList:render()
	---@type {link: Widget, flag: string}[]
	local streams = self:_parse()

	local columnBreak = assert(tonumber(self.props.columnbreak), 'Invalid "|columnbreak=" input')

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

	---@type Widget[]
	local parts = Array.map(segments, function(group)
		return UnorderedList{
			children = Array.map(group, function(data)
				return {
					Flags.Icon{flag = data.flag, shouldLink = false},
					' ',
					data.link,
				}
			end)
		}
	end)

	return Box{children = parts, paddingRight = '2em'}
end

---@private
---@return {link: Widget, flag: string}[]
function StreamList:_parse()
	---@param streamIndex integer
	---@return Widget?
	local makeLink = function(streamIndex)
		local stream = self.props['s' .. streamIndex] or self.props['link' .. streamIndex]
		if Logic.isEmpty(stream) then
			return
		end
		if Logic.isNotEmpty(self.props['link' .. streamIndex]) then
			return Link{
				link = self.props['link' .. streamIndex],
				children = self.props['display' .. streamIndex] or stream,
				linktype = 'external',
			}
		end

		local provider = string.lower(self.props['provider' .. streamIndex] or self.props.defaultprovider)
		assert(Table.includes(StreamLinks.countdownPlatformNames, provider), 'Invalid Provider: ' .. provider)
		if provider == 'afreeca' then
			provider = 'afreecatv'
		end

		return Link{
			link = 'Special:Stream/' .. provider .. '/' .. stream,
			children = self.props['display' .. streamIndex] or stream,
		}
	end

	return Array.mapIndexes(function(streamIndex)
		local link = makeLink(streamIndex)
		if not link then
			return
		end
		return {
			link = makeLink(streamIndex),
			flag = self.props['flag' .. streamIndex] or self.props.defaultflag,
		}
	end)
end

return StreamList
