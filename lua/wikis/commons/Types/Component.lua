---@class VNode<P>
---@field renderFn string|Component<P>
---@field props P

---@alias Context VNode<{parent: Context?, def: ContextDef, value: any, children: Renderable}>
---@alias HtmlNode VNode<{classes?: string[], css?: table, attr?: table, children: Renderable}>

---@alias Renderable string|Html|Widget|number|VNode

---@alias ContextDef<P> {defaultValue: P}

---@alias Component<P> fun(props: P, context: Context?): VNode<P>
---@alias ContextComponent Context<{parent: Context?, def: ContextDef, value: any, children: Renderable}>
---@alias HtmlComponent Context<{classes?: string[], css?: table, attr?: table, children: Renderable}>
