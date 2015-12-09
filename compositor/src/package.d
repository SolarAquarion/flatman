module composite;


public import
	core.thread,
	std.process,
	std.algorithm,
	std.array,
	std.datetime,
	std.string,
	std.math,
	std.stdio,
	std.file,
	std.path,
	std.conv,
	x11.X,
	x11.Xlib,
	x11.Xutil,
	x11.Xproto,
	x11.Xatom,
	x11.extensions.Xcomposite,
	x11.extensions.Xfixes,
	x11.extensions.XInput,
	x11.extensions.render,
	x11.extensions.Xrender,
	x11.keysymdef,
	ws.wm,
	ws.math,
	ws.x.property,
	composite.main,
	composite.client,
	composite.animation;


Screen screen;
ulong root;

enum CompositeRedirectManual = 1;