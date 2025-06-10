---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Patch = Lua.import('Module:Patch')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

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
---@param patchData StandardPatch
---@param placeholderText string?
---@return (string|Widget)[]
function CustomMap._formatPatchInfoCell(patchData, placeholderText)
	return {
		Link{
			link = patchData.pageName,
			children = patchData.displayName
		} or placeholderText,
		HtmlWidgets.Small{
			children = {patchData.releaseDate.string}
		}
	}
end

---@param args table
---@return Widget[]
function CustomMap:getReleaseCells(args)
	if Logic.isEmpty(args.releasedate) then
		return {}
	end

	local releasePatchData = Patch.getPatchByDate(args.releasedate) or {}
	local reworkPatchData = Patch.getPatchByDate(args.reworkdate) or {}

	local mapBuffPatchData = Patch.getPatchByDate(args['map buff']) or {}
	local mapBuff2PatchData = Patch.getPatchByDate(args['map buff 2']) or {}

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

---@param teamType 'atk'|'def'
---@return Widget
local function createTeamDisplayWidget(teamType)
	return HtmlWidgets.Fragment{
		children = {
			IconImageWidget{
				imageLight = 'R6S Para Bellum ' .. teamType .. ' logo.png',
				link = '',
				size = '14px'
			},
			' ',
			string.upper(teamType)
		}
	}
end

---@param args table
function CustomMap:getStatsCells(args)
	local wlData = mw.text.split(Template.safeExpand(mw.getCurrentFrame(), 'MapWL', {map = self.name}), ';')
	local atk_wins = wlData[1]
	local def_wins = wlData[2]
	local total = atk_wins + def_wins

	return {
		Title{children = 'Esports Statistics'},
		Cell{
			name = 'Win Rate',
			content = {
				HtmlWidgets.Fragment{children = {
					createTeamDisplayWidget('atk'),
					total > 0 and (atk_wins .. '/' .. total) or '-'
				}},
				HtmlWidgets.Fragment{children = {
					createTeamDisplayWidget('def'),
					total > 0 and (def_wins .. '/' .. total) or '-'
				}}
			}
		}
	}
end

function CustomMap:createBottomContent()
	return Template.safeExpand(mw.getCurrentFrame(), 'Recent on map', {limit = 500, map = self.name})
end

return CustomMap
