---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Patch = Lua.import('Module:Patch')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')
local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local Link = Lua.import('Module:Widget/Basic/Link')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

local MapWL = Lua.import('Module:MapWL')

---@class RainbowsixMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class RainbowsixMapInfoboxWidgetInjector: WidgetInjector
---@field caller RainbowsixMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'release' then
		return self.caller:getReleaseCells(args)
	elseif id == 'custom' then
		return WidgetUtil.collect(
			Cell{name = 'Theme', content = {args.theme}},
			Cell{name = 'Versions', content = {args.versions}},
			Cell{name = 'Layout', content = {args.layout}},
			Cell{name = 'Playlists', content = {args.playlists}},
			Cell{name = 'Day/Night Variant', content = {args['day/night variant']}},
			self.caller:getStatsCells(args)
		)
	end
	return widgets
end

---@private
---@param patchData StandardPatch?
---@param placeholderText string?
---@return (string|Widget)[]
function CustomMap._formatPatchInfoCell(patchData, placeholderText)
	if Logic.isEmpty(patchData) then
		return {placeholderText}
	end
	---@cast patchData -nil

	return {
		Link{
			link = patchData.pageName,
			children = patchData.displayName
		},
		HtmlWidgets.Small{
			children = {DateExt.toYmdInUtc(patchData.releaseDate)}
		}
	}
end

---@param args table
---@return Widget[]
function CustomMap:getReleaseCells(args)
	if Logic.isEmpty(args.releasedate) then
		return {}
	end

	local releasePatchData = Patch.getPatchByDate(args.releasedate)
	local reworkPatchData = args.reworkdate and Patch.getPatchByDate(args.reworkdate) or {}

	local mapBuffPatchData = args['map buff'] and Patch.getPatchByDate(args['map buff']) or {}
	local mapBuff2PatchData = args['map buff 2'] and Patch.getPatchByDate(args['map buff 2']) or {}

	return {
		Cell{
			name = 'Released',
			content = CustomMap._formatPatchInfoCell(releasePatchData, 'Launch')
		},
		Cell{
			name = 'Reworked',
			content = Logic.isNotEmpty(reworkPatchData) and CustomMap._formatPatchInfoCell(reworkPatchData) or nil
		},
		Cell{
			name = 'Map buff',
			content = Logic.isNotEmpty(mapBuffPatchData) and CustomMap._formatPatchInfoCell(mapBuffPatchData) or nil
		},
		Cell{
			name = 'Map buff 2',
			content = Logic.isNotEmpty(mapBuff2PatchData) and CustomMap._formatPatchInfoCell(mapBuff2PatchData) or nil
		}
	}
end

---@private
---@param teamType 'atk'|'def'
---@return Widget
function CustomMap._createTeamDisplayWidget(teamType)
	local lookupKey = {
		atk = 'attackTeam',
		def = 'defenseTeam',
	}
	return HtmlWidgets.Fragment{
		children = {
			AutoInlineIcon.display{onlyicon = true, category = 'M', lookup = lookupKey[teamType]},
			' ',
			string.upper(teamType)
		}
	}
end

---@param args table
function CustomMap:getStatsCells(args)
	local wlData = Array.parseCommaSeparatedString(MapWL.create{map = self.name}, ';')
	local attackWins = tonumber(wlData[1]) or 0
	local defenseWins = tonumber(wlData[2]) or 0
	local total = attackWins + defenseWins

	---@param value number
	---@param numberOfDecimals integer?
	---@return nil
	local function formatPercentage(value, numberOfDecimals)
		if not value then
			return nil
		end
		numberOfDecimals = numberOfDecimals or 0
		local format = '%.'.. numberOfDecimals ..'f'
		return string.format(format, MathUtil.round(value * 100, numberOfDecimals)) .. '%'
	end

	---@param wins number
	---@return string
	local function formatWinRateDisplay(wins)
		if total <= 0 then
			return '-'
		end
		return String.interpolate(
			'${percentage} (${wins})',
			{
				percentage = formatPercentage(wins / total, 2),
				wins = wins
			}
		)
	end

	return {
		Title{children = 'Esports Statistics'},
		Cell{
			name = 'Win Rate',
			content = {
				HtmlWidgets.Fragment{children = {
					CustomMap._createTeamDisplayWidget('atk'),
					': ',
					formatWinRateDisplay(attackWins)
				}},
				HtmlWidgets.Fragment{children = {
					CustomMap._createTeamDisplayWidget('def'),
					': ',
					formatWinRateDisplay(defenseWins)
				}}
			}
		}
	}
end

---@return string
function CustomMap:createBottomContent()
	return Template.safeExpand(mw.getCurrentFrame(), 'Recent on map', {limit = 500, map = self.name})
end

return CustomMap
