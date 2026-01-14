---
-- @Liquipedia
-- page=Module:Widget/Infobox/ShopMerch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')

local Button = Lua.import('Module:Widget/Basic/Button')
local Center = Lua.import('Module:Widget/Infobox/Center')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Title = Lua.import('Module:Widget/Infobox/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InfoboxShopMerchWidget: Widget
---@operator call(table): InfoboxShopMerchWidget
---@field args table<string, string>
local ShopMerch = Class.new(Widget)
ShopMerch.defaultProps = {
	args = {},
}

local ALLOWED_PREFIX = 'https://links.liquipedia.net/'
local ALLOWED_PREFIX_SCHEMELESS = 'links.liquipedia.net/'

local MAX_URL_LENGTH = 2000

local SHOP_DEFAULT_LINK = 'https://links.liquipedia.net/tlstore'
local SHOP_DEFAULT_ICON = 'shopping_bag'
local SHOP_DEFAULT_TEXT = 'Shop Official Team Liquid Gear'


---Only allow `https://links.liquipedia.net/...` (and scheme-less `links.liquipedia.net/...` inputs).
---Allows query parameters (e.g. UTM) and fragments.
---@param shopLink string?
---@return string? normalizedUrl
local function normalizeAndValidateShopLink(shopLink)
	if String.isEmpty(shopLink) then
		return
	end
	---@cast shopLink -nil

	shopLink = mw.text.trim(shopLink)

	if #shopLink > MAX_URL_LENGTH then
		return
	end

	if shopLink:find('[|`\\]<>') then
		return
	end

	local ALLOWED_URL_CHARS_PATTERN = "^[A-Za-z0-9%-%._~:/%?#%[%]@!$&'()%*%+,;=%%%%]+$"
	if not shopLink:match(ALLOWED_URL_CHARS_PATTERN) then
		return
	end

	local lower = shopLink:lower()

	if lower:sub(1, #ALLOWED_PREFIX) == ALLOWED_PREFIX then
		return shopLink
	end

	if lower:sub(1, #ALLOWED_PREFIX_SCHEMELESS) == ALLOWED_PREFIX_SCHEMELESS then
		return 'https://' .. shopLink
	end
end

---@return Widget[]?
function ShopMerch:render()
	local args = self.props.args or {}

	local rawShopLink = mw.text.trim(args.shoplink or '')
	if Logic.isEmpty(rawShopLink) then
		return
	end

	local shopLink = normalizeAndValidateShopLink(Logic.readBool(rawShopLink) and SHOP_DEFAULT_LINK or rawShopLink)
	if not shopLink then
		return
	end

	local buttonText = Logic.nilIfEmpty(args.shoptext) or SHOP_DEFAULT_TEXT
	local iconName = Logic.nilIfEmpty(args.shopicon) or SHOP_DEFAULT_ICON

	local children = WidgetUtil.collect(
		IconFa{iconName = iconName},
		' ',
		buttonText
	)

	return {
		Title{children = 'Shop Merch'},
		Center{children = {
			Button{
				linktype = 'external',
				variant = 'primary',
				size = 'md',
				link = shopLink,
				children = children,
			},
			'Purchases through this link support Liquipedia.',
		}},
	}
end

return ShopMerch
