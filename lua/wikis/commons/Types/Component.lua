
---@class VNode<P>
---@field renderFn string|Component<P>
---@field props P

---@alias Context VNode<{parent: Context?, def: ContextDef, value: any, children: Renderable}>
---@alias LeafNode VNode<{classes?: string[], css?: table, attr?: table, children: Renderable}>

---@alias Renderable string|Html|Widget|number|VNode

---@alias ContextDef {defaultValue: any}

---@alias Component<P> fun(props: P, context: Context?): VNode<P>
