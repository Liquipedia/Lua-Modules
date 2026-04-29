--- Triple Comment to Enable our LLS Plugin
local ComponentCore = require('Module:Components/Component')
local Context = require('Module:Components/Context')
local Html = require('Module:Components/Html')
local WidgetHtml = require('Module:Widget/Html/All')
local Renderer = require('Module:Components/Renderer')

describe('Components/Renderer', function()
	describe('Renderer.render', function()
		it('returns empty string for nil', function()
			assert.are.equal('', Renderer.render(nil))
		end)

		it('renders a string', function()
			assert.are.equal('hello', Renderer.render('hello'))
		end)

		it('renders a number', function()
			assert.are.equal('42', Renderer.render(42))
		end)

		it('returns empty string for empty table', function()
			assert.are.equal('', Renderer.render({}))
		end)

		it('renders an array of primitives', function()
			assert.are.equal('abc', Renderer.render({'a', 'b', 'c'}))
		end)

		it('renders a mixed array', function()
			assert.are.equal('hello42world', Renderer.render({'hello', 42, 'world'}))
		end)

		it('renders an HTML tag VNode', function()
			local vNode = Html.Span{}
			assert.are.equal('<span></span>', tostring(vNode))
		end)

		it('renders HTML tag with children', function()
			local vNode = Html.Div{children = {'hello'}}
			assert.are.equal('<div>hello</div>', tostring(vNode))
		end)

		it('renders HTML tag with classes', function()
			local vNode = Html.Div{classes = {'foo', 'bar'}}
			assert.are.equal('<div class="foo bar"></div>', tostring(vNode))
		end)

		it('renders HTML tag with css', function()
			local vNode = Html.Span{css = {color = 'red'}}
			local result = tostring(vNode)
			assert.is_true(result:find('color:red', nil, true) ~= nil or result:find('color: red', nil, true) ~= nil)
		end)

		it('renders HTML tag with attributes', function()
			local vNode = Html.Span{attributes = {id = 'my-id'}}
			assert.is_true(tostring(vNode):find('id="my-id"', nil, true) ~= nil)
		end)

		it('renders nested HTML tags', function()
			local vNode = Html.Div{children = {Html.Span{children = {'inner'}}}}
			assert.are.equal('<div><span>inner</span></div>', tostring(vNode))
		end)

		it('renders fragment without wrapper tag', function()
			local vNode = Html.Fragment{children = {'a', 'b'}}
			assert.are.equal('ab', tostring(vNode))
		end)

		it('renders a functional component', function()
			local MyComp = ComponentCore.component(function(props)
				return Html.Span{children = {props.text}}
			end)
			local result = tostring(MyComp{text = 'hi'})
			assert.are.equal('<span>hi</span>', result)
		end)

		it('renders functional component with defaultProps', function()
			local MyComp = ComponentCore.component(function(props)
				return Html.Span{children = {props.label}}
			end, {label = 'default'})
			assert.are.equal('<span>default</span>', tostring(MyComp{}))
			assert.are.equal('<span>override</span>', tostring(MyComp{label = 'override'}))
		end)

		it('errors on invalid non-table VNode type', function()
			assert.is.error(function()
				---@diagnostic disable-next-line: param-type-mismatch
				Renderer.render(true)
			end)
		end)

		it('errors on invalid table VNode (no renderFn, no __tostring, no _build)', function()
			assert.is.error(function()
				Renderer.render({someKey = 'someValue'})
			end)
		end)

		it('renders mw.html', function()
			assert.are.equal('<p>built</p>', tostring(mw.html.create('p'):wikitext('built')))
		end)

		it('renders widget2', function()
			assert.are.equal('<p>built</p>', tostring(WidgetHtml.P{children = {'built'}}))
		end)
	end)
end)

describe('Components/Component', function()
	describe('ComponentCore.component', function()
		it('returns a callable component', function()
			local MyComp = ComponentCore.component(function(props)
				return props.x
			end)
			assert.are.equal('hello', Renderer.render(MyComp{x = 'hello'}))
		end)

		it('applies defaultProps for missing keys', function()
			local MyComp = ComponentCore.component(function(props)
				return props.val
			end, {val = 'fallback'})
			assert.are.equal('fallback', Renderer.render(MyComp{}))
		end)

		it('explicit props override defaultProps', function()
			local MyComp = ComponentCore.component(function(props)
				return props.val
			end, {val = 'fallback'})
			assert.are.equal('explicit', Renderer.render(MyComp{val = 'explicit'}))
		end)

		it('works with nil props (no call argument)', function()
			local MyComp = ComponentCore.component(function(props)
				return props.val or 'none'
			end)
			assert.are.equal('none', Renderer.render(MyComp()))
		end)
	end)

	describe('ComponentCore.tag', function()
		it('creates an HTML tag component', function()
			local MyTag = ComponentCore.tag('section')
			assert.are.equal('<section></section>', tostring(MyTag{}))
		end)

		it('created tag accepts classes', function()
			local MyTag = ComponentCore.tag('section')
			assert.are.equal('<section class="hero"></section>', tostring(MyTag{classes = {'hero'}}))
		end)
	end)
end)

describe('Components/Context', function()
	describe('Context.create', function()
		it('returns a context definition with defaultValue', function()
			local def = Context.create('my-default')
			assert.are.equal('my-default', def.defaultValue)
		end)
	end)

	describe('Context.Provider and Context.read', function()
		it('returns defaultValue when context is nil', function()
			local def = Context.create('default')
			assert.are.equal('default', Context.read(nil, def))
		end)

		it('provides a value to children via render', function()
			local def = Context.create('default')

			local MyComp = ComponentCore.component(function(props, context)
				return Context.read(context, def)
			end)

			local tree = Context.Provider{
				def = def,
				value = 'provided',
				children = {MyComp{}}
			}
			assert.are.equal('provided', tostring(tree))
		end)

		it('nested providers shadow outer providers', function()
			local def = Context.create('default')

			local MyComp = ComponentCore.component(function(props, context)
				return Context.read(context, def)
			end)

			local tree = Context.Provider{
				def = def,
				value = 'outer',
				children = {
					Context.Provider{
						def = def,
						value = 'inner',
						children = {MyComp{}}
					}
				}
			}
			assert.are.equal('inner', tostring(tree))
		end)

		it('outer context still accessible outside nested provider', function()
			local def = Context.create('default')

			local MyComp = ComponentCore.component(function(props, context)
				return Context.read(context, def)
			end)

			local tree = Context.Provider{
				def = def,
				value = 'outer',
				children = {
					MyComp{},
					Context.Provider{
						def = def,
						value = 'inner',
						children = {MyComp{}}
					},
					MyComp{},
				}
			}
			assert.are.equal('outerinnerouter', tostring(tree))
		end)

		it('uses defaultValue when no provider wraps the component', function()
			local def = Context.create('fallback')

			local MyComp = ComponentCore.component(function(props, context)
				return Context.read(context, def)
			end)

			assert.are.equal('fallback', tostring(MyComp{}))
		end)
	end)
end)

describe('Components/Html', function()
	it('Html.Div renders a div', function()
		assert.are.equal('<div></div>', tostring(Html.Div{}))
	end)

	it('Html.Span renders a span', function()
		assert.are.equal('<span></span>', tostring(Html.Span{}))
	end)

	it('Html.Ul with Li children', function()
		local result = tostring(Html.Ul{children = {
			Html.Li{children = {'item1'}},
			Html.Li{children = {'item2'}},
		}})
		assert.are.equal('<ul><li>item1</li><li>item2</li></ul>', result)
	end)

	it('Html.Table with nested structure', function()
		local result = tostring(Html.Table{children = {
			Html.Tbody{children = {
				Html.Tr{children = {
					Html.Td{children = {'cell'}}
				}}
			}}
		}})
		assert.are.equal('<table><tbody><tr><td>cell</td></tr></tbody></table>', result)
	end)

	it('Html.Br renders self-closing br tag', function()
		assert.are.equal('<br />', tostring(Html.Br{}))
	end)

	it('Html.Hr renders self-closing hr tag', function()
		assert.are.equal('<hr />', tostring(Html.Hr{}))
	end)

	it('Html.Strong renders with children', function()
		assert.are.equal('<strong>bold</strong>', tostring(Html.Strong{children = {'bold'}}))
	end)

	it('Html.Fragment renders children without wrapper', function()
		local result = tostring(Html.Fragment{children = {
			Html.Span{children = {'a'}},
			Html.Span{children = {'b'}},
		}})
		assert.are.equal('<span>a</span><span>b</span>', result)
	end)
end)
