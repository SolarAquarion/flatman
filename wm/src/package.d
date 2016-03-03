module flatman;

public import
	core.stdc.signal,
	core.sys.posix.unistd,
	core.sys.posix.signal,
	core.stdc.locale,
	core.sys.posix.sys.wait,
	core.runtime,
	core.thread,
	core.stdc.stdlib,
	std.parallelism,
	std.regex,
	std.traits,
	std.process,
	std.path,
	std.stdio,
	std.algorithm,
	std.array,
	std.math,
	std.string,
	std.conv,
	std.datetime,
	std.file,
	std.functional,
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
	ws.math,
	ws.inotify,
	ws.time,
	ws.gui.base,
	ws.gui.input,
	ws.x.draw,
	ws.x.property,
	ws.decode,
	ws.bindings.fontconfig,
	ws.bindings.xft,
	flatman.util,
	flatman.ewmh,
	flatman.flatman,
	flatman.monitor,
	flatman.workspace,
	flatman.container,
	flatman.split,
	flatman.floating,
	flatman.tabs,
	flatman.client,
	flatman.commands,
	flatman.config,
	flatman.keybinds;
