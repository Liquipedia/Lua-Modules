---
-- @Liquipedia
-- page=Module:Widget/SpellCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ITEM_DISPLAY = {
	{base = 'health', text = 'Health'},
	{base = 'shield', text = 'Shield'},
	{base = 'damage', text = 'Damage'},
	{base = 'healing', text = 'Healing'},
	{base = 'damageboost', text = 'Damage Boost'},
	{base = 'speedboost', text = 'Speed Boost'},
	{base = 'healthboost', text = 'Health Boost'},
	{base = 'rangeboost', text = 'Range Boost'},
	{base = 'durationboost', text = 'Duration Boost'},
	{base = 'projectilespeedboost', text = 'Projectile Speed Boost'},
	{base = 'movespeed', text = 'Movespeed'},
	{base = 'range', text = 'Range'},
	{base = 'width', text = 'Width'},
	{base = 'spread', text = 'Spread'},
	{base = 'reload', text = 'Reload Speed'},
	{base = 'projectiles', text = 'Projectiles'},
	{base = 'projectilespeed', text = 'Projectile Speed'},
	{base = 'charge', text = 'Super Charge'},
	{base = 'hcharge', text = 'Hypercharge Charge'},
	{base = 'multiplier', text = 'Hypercharge Multiplier'},
	{base = 'duration', text = 'Duration'},
	{base = 'quantity', text = 'Quantity'},
	{base = 'delay', text = 'Delay'},
	{base = 'cooldown', text = 'Cooldown'},
}

local SpellCard = {}
SpellCard.defaultProps = {
	name = 'missing name',
}

---@param props table
---@return VNode
function SpellCard.render(props)
	return TableWidgets.Table{
		css = {['margin-bottom'] = '0.5rem'},
		columns = {
			{width = '76px'},
			{width = '372px'},
		},
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = TableWidgets.CellHeader{
						colspan = 2,
						classes = {'wiki-backgroundcolor-light'},
						children = props.name,
					}
				}
			},
			TableWidgets.TableBody{
				children = {
					TableWidgets.Row{
						children = {
							TableWidgets.Cell{
								children = Image{
									imageLight = props.image,
									imageDark = props.imageDark,
									size = '64x64px',
								}
							},
							TableWidgets.Cell{
								css = {['white-space'] = 'normal'}, -- to make it wrap...
								children = props.description,
							},
						},
					},
					TableWidgets.Row{
						children = TableWidgets.Cell{colspan = 2, children = SpellCard._renderData(props)},
					},
				}
			}
		}
	}
end

---@private
---@param props table
---@return VNode
function SpellCard._renderData(props)
	---@param info {base: string, text: string}
	---@return VNode?
	local makeCell = function(info)
		local base = info.base
		local items = Array.mapIndexes(function(index)
			return props[base .. index] or index == 1 and props[base] or nil
		end)

		if Logic.isEmpty(items) then return end

		items = Array.interleave(items, Html.Br{})

		return Html.Div{
			css = {padding = '0.125rem 0.5rem'},
			children = WidgetUtil.collect(
				Html.B{children = info.text},
				Html.Br{},
				items
			)
		}
	end

	return Html.Div{
		css = {
			width = '100%',
			['white-space'] = 'normal',
			['font-size'] = '90%',
			display = 'flex',
			['flex-wrap'] = 'wrap',
			['align-content'] = 'stretch',
		},
		children = Array.map(ITEM_DISPLAY, makeCell),
	}
end

return Component.component(SpellCard.render, SpellCard.defaultProps)
