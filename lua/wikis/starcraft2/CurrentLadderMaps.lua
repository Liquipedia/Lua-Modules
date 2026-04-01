local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Page = Lua.import('Module:Page')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CurrentLadderMaps = {}

---@param frame Frame
---@return Widget
function CurrentLadderMaps.run(frame)
	local args = Arguments.getArgs(frame)

	---@param prefix string
	---@param index integer
	---@return {}?
	local readInput = function(prefix, index)
		local input = args[prefix .. '_' .. index]
		if not input then return end
		local mapData = CurrentLadderMaps._fetchSingle(input)
		local extradata = mapData.extradata or {}
		return {
			text = args[prefix .. '_' .. index .. 'text'],
			spawns = extradata.spawns,
			pageName = mapData.pagename or Page.pageifyLink(input),
			displayName = mapData.name or input,
			image = mapData.image,
			creator =  extradata.creator1dn or extradata.creator1 or extradata.creator or 'unknown',
		}
	end

	local data = {
		{mode = '1v1', maps = Array.mapIndexes(FnUtil.curry(readInput, '1v1'))},
		{mode = '2v2', maps = Array.mapIndexes(FnUtil.curry(readInput, '2v2'))},
		{mode = '3v3', maps = Array.mapIndexes(FnUtil.curry(readInput, '3v3'))},
		{mode = '4v4', maps = Array.mapIndexes(FnUtil.curry(readInput, '4v4'))},
	}

	return HtmlWidgets.Fragment{
		children = {
			CurrentLadderMaps._mapsOverview(data),
			HtmlWidgets.Br{},
			CurrentLadderMaps._mapsDetails(data),
		}
	}
end

---@private
---@param map string
---@return datapoint
function CurrentLadderMaps._fetchSingle(map)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, 'map'),
		ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(map)),
	}

	return mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(conditions),
		query = 'name, pagename, extradata, image',
		limit = 1
	})[1] or {}
end

---@private
---@param data {mode:string, maps: {pageName: string, displayName: string, text: string?, spawns: string?, image: string?, creator: string}[]}[]
---@return Widget
function CurrentLadderMaps._mapsOverview(data)
	return TableWidgets.Table{
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = Array.map(data, function(item)
						return TableWidgets.CellHeader{children = item.mode}
					end),
				}
			},
			TableWidgets.TableBody{
				children = TableWidgets.Row{
					children = Array.map(data, function(item)
						return TableWidgets.Cell{
							children = UnorderedList{
								children = Array.map(item.maps, function (map)
									return {
										Link{link = map.pageName, children = map.displayName},
										map.spawns and (' (' .. map.spawns .. ')') or nil,
									}
								end)
							}
						}
					end),
				}
			},
		},
		footer = 'Above maps are listed in the map preferences.'
	}
end

---@private
---@param data {mode:string, maps: {pageName: string, displayName: string, text: string?, spawns: string?, image: string?, creator: string}[]}[]
---@return Widget
function CurrentLadderMaps._mapsDetails(data)
	return HtmlWidgets.Div{
		classes = {'row'},
		children = Array.map(data, function(info)
			return HtmlWidgets.Div{
				classes = {'col-lg-3', 'col-md-6', 'col-sm-6', 'col-xs-12'},
				children = TableWidgets.Table{
					tableClasses = {'collapsible', 'collapsed'},
					css = {width = '100%'},
					children = {
						TableWidgets.TableHeader{
							children = TableWidgets.Row{
								children = TableWidgets.CellHeader{
									children = {
										info.mode,
										' Ladder Maps',
									},
								}
							}
						},
						TableWidgets.TableBody{
							children = Array.map(info.maps, CurrentLadderMaps._mapDetails),
						},
					},
				}
			}
		end)
	}
end

---@private
---@param map {pageName: string, displayName: string, text: string?, spawns: string?, image: string?, creator: string}
---@return Widget
function CurrentLadderMaps._mapDetails(map)
	return TableWidgets.Row{
		children = TableWidgets.Cell{
			children = WidgetUtil.collect(
				HtmlWidgets.B{children = Link{link = map.pageName, children = map.displayName}},
				map.spawns and (' (' .. map.spawns .. ')') or nil,
				map.image and Image{
					imageLight = map.image,
					size = '150px',
					caption = 'Created by: ' .. map.creator,
					alignment = 'thumb',
					location = 'right',
					alt = map.displayName,
				} or nil,
				HtmlWidgets.Br{},
				HtmlWidgets.I{
					css = {['white-space'] = 'normal'},
					children = map.text,
				}
			),
		},
	}
end

return CurrentLadderMaps
