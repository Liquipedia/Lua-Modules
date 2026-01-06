---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local CharacterIcon = Lua.import('Module:CharacterIcon')

local Patch = Lua.import('Module:Infobox/Patch')
local Injector = Lua.import('Module:Widget/Injector')
local Widgets = Lua.import('Module:Widget/All')

---@class Dota2PatchInfobox: PatchInfobox
---@operator call(Frame): Dota2PatchInfobox
local CustomPatch = Class.new(Patch)

---@class Dota2PatchInfoboxWidgetInjector: WidgetInjector
---@operator call(Dota2PatchInfobox): Dota2PatchInfoboxWidgetInjector
---@field caller Dota2PatchInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomPatch.run(frame)
	local patch = CustomPatch(frame)
	patch:setWidgetInjector(CustomInjector(patch))

	return patch:createInfobox()
end

---@param frame Frame
---@return Widget
function CustomPatch.runLegacy(frame)
	local patch = CustomPatch(frame)
	local args = patch.args
	args.release = args.dota2
	args.informationType = 'version'
	patch:setWidgetInjector(CustomInjector(patch))

	Array.forEach(
		Array.parseCommaSeparatedString(args.highlights, '\n?*'),
		function (highlight, highlightIndex)
			args['highlight' .. highlightIndex] = highlight
		end
	)

	return patch:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		---@param characterInput string
		---@return string[]
		local function toCharacterList(characterInput)
			return Array.map(
				Array.parseCommaSeparatedString(characterInput),
				function (character)
					return CharacterIcon.Icon{
						character = character,
						date = args.release,
						size = '40px',
						addTextLink = true,
					}
				end
			)
		end

		return {
			Widgets.Cell{
				name = 'New Heroes',
				children = toCharacterList(args.new),
				options = {columns = 3, suppressColon = true},
			},
			Widgets.Cell{
				name = 'Nerfed Heroes',
				children = toCharacterList(args.nerfed),
				options = {columns = 3, suppressColon = true},
			},
			Widgets.Cell{
				name = 'Buffed Heroes',
				children = toCharacterList(args.buffed),
				options = {columns = 3, suppressColon = true},
			},
			Widgets.Cell{
				name = 'Rebalanced Heroes',
				children = toCharacterList(args.rebalanced),
				options = {columns = 3, suppressColon = true},
			},
			Widgets.Cell{
				name = 'Reworked Heroes',
				children = toCharacterList(args.reworked),
				options = {columns = 3, suppressColon = true},
			},
		}
	end
	return widgets
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local informationType = self:getInformationType(args):lower()

	local data = {
		previous = CustomPatch:_getChronology('before', args.release, informationType),
		next = CustomPatch:_getChronology('after', args.release, informationType),
	}
	return data
end

---@param time 'before' | 'after'
---@param date string
---@param informationType string
---@return string
function CustomPatch:_getChronology(time, date, informationType)
	local timeModifier = time == 'before' and '<' or '>'
	return (mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::'.. informationType ..']] and [[date::'.. timeModifier .. date ..']]',
		order = 'date ' .. (time == 'before' and 'DESC' or 'ASC'),
		limit = 1,
	})[1] or {}).name
end

function CustomPatch:addToLpdb(lpdbData, args)
	lpdbData.date = args.release or args.dota

	lpdbData.extradata.version = args.name or ''
	lpdbData.extradata.new = args.new or ''
	lpdbData.extradata.nerfed = args.nerfed or ''
	lpdbData.extradata.buffed = args.buffed or ''
	lpdbData.extradata.rebalanced = args.rebalanced or ''
	lpdbData.extradata.reworked = args.reworked or ''
	lpdbData.extradata.significant = args.significant or 'no'
	lpdbData.extradata.dota2 = args.release or ''
	lpdbData.extradata.dota = args.dota or ''

	return lpdbData
end


return CustomPatch
