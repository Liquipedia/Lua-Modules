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

local SHOP_DEFAULT_ICON = 'fas fa-shopping-bag'
local SHOP_DEFAULT_TEXT = 'Shop in the Liquipedia Store'


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

	if shopLink:find('[|`\\]') then
		return
	end

	if not shopLink:match("^[A-Za-z0-9%-%._~:/%?#%[%]@!$&'()%*%+,;=%%%%]+$") then
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

	local shopLink = normalizeAndValidateShopLink(args.shoplink)
	if not shopLink then
		return
	end

	local buttonText = Logic.nilIfEmpty(args.shoptext) or SHOP_DEFAULT_TEXT
	local iconName = Logic.nilIfEmpty(args.shopicon) or SHOP_DEFAULT_ICON
	local hasIcon = Logic.isNotEmpty(iconName)

	local children = WidgetUtil.collect(
		hasIcon and IconFa{iconName = iconName} or nil,
		hasIcon and ' ' or nil,
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
