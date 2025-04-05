/* eslint-disable @typescript-eslint/no-empty-object-type */
import * as React from "react";
declare global {
	namespace WidgetFactory {
		function createElement(type: JSX.ElementType, props?: object, ...children: React.ReactNode[]): React.ReactNode;
	}
	namespace JSX {
		/* Don't think all of these are needed, but some are */
		/* from https://github.com/eps1lon/DefinitelyTyped/blob/master/types/react/jsx-dev-runtime.d.ts */
		type ElementType = React.JSX.ElementType;
		interface Element extends React.JSX.Element { }
		interface ElementClass extends React.JSX.ElementClass { }
		interface ElementAttributesProperty extends React.JSX.ElementAttributesProperty { }
		interface ElementChildrenAttribute extends React.JSX.ElementChildrenAttribute { }
		type LibraryManagedAttributes<C, P> = React.JSX.LibraryManagedAttributes<C, P>;
		interface IntrinsicAttributes extends React.JSX.IntrinsicAttributes { }
		interface IntrinsicClassAttributes<T> extends React.JSX.IntrinsicClassAttributes<T> { }
		interface IntrinsicElements extends React.JSX.IntrinsicElements { }
	}
}
