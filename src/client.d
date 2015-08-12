module flatman.client;

import flatman;

__gshared:


enum BUTTONMASK = ButtonPressMask|ButtonReleaseMask;
enum MOUSEMASK = BUTTONMASK|PointerMotionMask;


class Client: Base {

	string name;
	float mina, maxa;
	int[2] posFloating;
	int[2] sizeFloating;
	int basew, baseh, incw, inch, maxw, maxh, minw, minh;
	int bw, oldbw;
	bool isUrgent;
	bool isFloating;
	bool global;
	bool isfixed, neverfocus, oldstate, isfullscreen;
	flatman.Monitor monitor;
	Window win;

	Pixmap mPixmap;
	Picture mPicture;
	XRenderPictFormat* format;

	this(Window win, flatman.Monitor monitor){
		this.monitor = monitor;
		XSync(dpy, false);
		this.win = win;
		XWindowAttributes attr;
		XGetWindowAttributes(dpy, win, &attr);
		pos = [attr.x, attr.y];
		posFloating = pos;
		size = [attr.width, attr.height];
		sizeFloating = size;
		updateType;
		updateSizeHints;
		updateWmHints;
		//updateWorkspace;
		updateStrut;
	}

	override void hide(){
		"hide %s".format(name).log;
		hidden = true;
		XUnmapWindow(dpy, win);
	}

	override void show(){
		"show %s".format(name).log;
		hidden = false;
		XMapWindow(dpy, win);
	}

	void raise(){
		XRaiseWindow(dpy, win);
	}

	void setWorkspace(long i){
		if(i >= 0 && i < monitor.workspaces.length && monitor.workspaces[i].clients.canFind(this))
			return;
		"set workspace %s %s".format(name, i).log;
		monitor.remove(this);
		monitor.add(this, i < 0 ? tags.length : i);
		updateWindowDesktop(this, i);
		"set workspace done".log;
	}

	void moveResize(int[2] pos, int[2] size){
		pos.x = pos.x.max(0);
		pos.y = pos.y.max(0);
		size.w = size.w.max(1);
		size.h = size.h.max(1);
		XWindowChanges wc;
		if(this.pos == pos && this.size == size)
			return;
		this.pos = pos;
		this.size = size;
		wc.x = pos.x;
		wc.y = pos.y;
		wc.width = size.w;
		wc.height = size.h;
		XConfigureWindow(dpy, win, CWX|CWY|CWWidth|CWHeight, &wc);
		configure;
		XSync(dpy, false);
	}

	void setState(long state){
		long[] data = [ state, None ];
		XChangeProperty(dpy, win, wm.state, wm.state, 32, PropModeReplace, cast(ubyte*)data, 2);
	}

	auto isVisible(){
		return (monitor.workspace.clients.canFind(this) || monitor.globals.canFind(this));
	}

	void configure(){
		XConfigureEvent ce;
		ce.type = ConfigureNotify;
		ce.display = dpy;
		ce.event = win;
		ce.window = win;
		ce.x = pos.x;
		ce.y = pos.y;
		ce.width = size.w;
		ce.height = size.h;
		ce.above = None;
		ce.override_redirect = false;
		XSendEvent(dpy, win, false, StructureNotifyMask, cast(XEvent*)&ce);
	}

	void updateType(){
		Atom[] state = this.getPropList(net.state);
		if(state.canFind(net.fullscreen))
			setfullscreen(this, true);
		if(state.canFind(net.modal))
			isFloating = true;
		Atom[] type = this.getPropList(net.windowType);
		if(type.canFind(net.windowTypeDialog) || type.canFind(net.windowTypeSplash))
			isFloating = true;
		if(type.canFind(net.windowTypeDock)){
			if(!global){
				global = true;
				flatman.monitor.remove(this);
				flatman.monitor.add(this);
			}
		}
		/+else if(global){
			global = false;
			monitor.remove(this);
			monitor.add(this);
		}+/
	}

	void updateSizeHints(){
		long msize;
		XSizeHints size;
		if(!XGetWMNormalHints(dpy, win, &size, &msize))
			/* size is uninitialized, ensure that size.flags aren't used */
			size.flags = PSize;
		if(size.flags & PBaseSize){
			basew = size.base_width;
			baseh = size.base_height;
		}else if(size.flags & PMinSize){
			basew = size.min_width;
			baseh = size.min_height;
		}else
			basew = baseh = 0;
		if(size.flags & PResizeInc){
			incw = size.width_inc;
			inch = size.height_inc;
		}else
			incw = inch = 0;
		if(size.flags & PMaxSize){
			maxw = size.max_width;
			maxh = size.max_height;
		}else
			maxw = maxh = 0;
		if(size.flags & PMinSize){
			minw = size.min_width;
			minh = size.min_height;
		}else if(size.flags & PBaseSize){
			minw = size.base_width;
			minh = size.base_height;
		}else
			minw = minh = 0;
		if(size.flags & PAspect){
			mina = cast(float)size.min_aspect.y / size.min_aspect.x;
			maxa = cast(float)size.max_aspect.x / size.max_aspect.y;
		}else
			maxa = mina = 0.0;
		isfixed = (maxw && minw && maxh && minh && maxw == minw && maxh == minh);
	}

	void updateWmHints(){
		XWMHints* wmh = XGetWMHints(dpy, win);
		if(wmh){
			if(this == flatman.monitor.active && wmh.flags & XUrgencyHint){
				wmh.flags &= ~XUrgencyHint;
				XSetWMHints(dpy, win, wmh);
			}else{
				isUrgent = (wmh.flags & XUrgencyHint) ? true : false;
				//flatman.monitor.dock.show;
			}
			if(wmh.flags & InputHint)
				neverfocus = !wmh.input;
			else
				neverfocus = false;
			XFree(wmh);
		}
	}

	void updateWorkspace(){
		int ws = originWorkspace;
		setWorkspace(ws);
	}

	int originWorkspace(){
		string env;
		try {
			XSync(dpy, false);
			env = "/proc/%d/environ".format(win.getprop!CARDINAL(net.pid)).readText;
			auto match = matchFirst(env, r"FLATMAN_WORKSPACE=([0-9]+)");
			"origin %s: %s".format(name, match).log;
			return match[1].to!int;
		}catch(Exception e)
			try
				"pid error: %s".format(win.getprop!CARDINAL(net.pid)).log;
			catch
				"no pid for %s".format(name).log;
		try
			return cast(int)win.getprop!CARDINAL(net.windowDesktop);
		catch{}
		return monitor.workspaceActive;
	}

	void updateStrut(){
		monitor.strut(this, this.getPropList(net.strutPartial).length>0);
	}

	void requestAttention(){
		if(this == monitor.active){
			isUrgent = false;
			return;
		}
		if(!isVisible && this != previousFocus)
			"%s requests attention".format(name).log;
		isUrgent = true;
	}

	Picture picture(){
		if(!mPicture){
			// Increase the ref count for the backing pixmap
			if(!mPixmap)
				mPixmap = XCompositeNameWindowPixmap(dpy, win);
			// Create the window picture
			mPicture = XRenderCreatePicture(dpy, mPixmap, format, 0, null);
		}
		// ### There's room for optimization here. The window picture only needs a clip region when it's translucent. For opaque windows it doesn't matter since we're drawing them top -> bottom.
		/+
		if(!mSourceClipValid){
			XserverRegion clip = XFixesCreateRegionFromWindow( dpy, winId(), WindowRegionBounding );
			XFixesSetPictureClipRegion( dpy, mPicture, 0, 0, clip );
			XFixesDestroyRegion( dpy, clip );
			mSourceClipValid = true;
		}
		+/
		return mPicture;
	}

};

void sendmon(Client c, Monitor m){
	if(c.monitor == m)
		return;
	unfocus(c, true);
	c.monitor.remove(c);
	c.monitor = m;
	c.monitor.add(c);
	focus(null);
}

bool sendevent(Client c, Atom proto){
	int n;
	Atom *protocols;
	bool exists = false;
	XEvent ev;
	if(XGetWMProtocols(dpy, c.win, &protocols, &n)){
		while(!exists && n--)
			exists = protocols[n] == proto;
		XFree(protocols);
	}
	if(exists){
		ev.type = ClientMessage;
		ev.xclient.window = c.win;
		ev.xclient.message_type = wm.protocols;
		ev.xclient.format = 32;
		ev.xclient.data.l[0] = proto;
		ev.xclient.data.l[1] = CurrentTime;
		XSendEvent(dpy, c.win, false, NoEventMask, &ev);
	}
	return exists;
}

void setfocus(Client c){
	if(!c.neverfocus){
		XSetInputFocus(dpy, c.win, RevertToPointerRoot, CurrentTime);
		XChangeProperty(dpy, root, net.windowActive,
 		                XA_WINDOW, 32, PropModeReplace,
 		                cast(ubyte*) &(c.win), 1);
	}
	sendevent(c, wm.takeFocus);
}

void setfullscreen(Client c, bool fullscreen){
	auto proplist = c.getPropList(net.state);
	if(fullscreen){
		if(!proplist.canFind(net.fullscreen)){
			append(c.win, net.state, [net.fullscreen]);
		}
		c.isfullscreen = true;
		c.posFloating = c.pos;
		c.sizeFloating = c.size;
		c.moveResize(c.monitor.pos, c.monitor.size);
		XRaiseWindow(dpy, c.win);
	}else{
		if(proplist.canFind(net.fullscreen)){
			replace(c.win, net.state, c.getPropList(net.state).without(net.fullscreen));
		}
		//XChangeProperty(dpy, c.win, net.state, XA_ATOM, 32, PropModeReplace, null, 0);
		c.isfullscreen = false;
		c.pos = c.posFloating;
		c.size = c.sizeFloating;
		c.moveResize(c.pos, c.size);
	}
}

void unfocus(Client c, bool setfocus){
	if(!c)
		return;
	grabbuttons(c, false);
	if(setfocus){
		XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
		XDeleteProperty(dpy, root, net.windowActive);
	}
}

void unmanage(Client c, bool force=false){
	if(force || !c.hidden)
		c.monitor.remove(c);
	else{
		XWindowChanges wc;
		wc.border_width = c.oldbw;
		XGrabServer(dpy);
		XSetErrorHandler(&xerrordummy);
		XUngrabButton(dpy, AnyButton, AnyModifier, c.win);
		c.setState(WithdrawnState);
		XSync(dpy, false);
		XSetErrorHandler(&xerror);
		XUngrabServer(dpy);
	}
	focus(null);
	updateClientList();
}

void updatetitle(Client c){
	if(!gettextprop(c.win, net.name, c.name))
		gettextprop(c.win, XA_WM_NAME, c.name);
	if(!c.name.length)
		c.name = broken;
}

void applyRules(Client c){
	string _class, instance;
	uint i;
	const(Rule)* r;
	XClassHint ch = { null, null };
	/* rule matching */
	XGetClassHint(dpy, c.win, &ch);
	_class    = to!string(ch.res_class ? ch.res_class : broken);
	instance = to!string(ch.res_name  ? ch.res_name  : broken);
	for(i = 0; i < rules.length; i++){
		r = &rules[i];
		if(
			(!r.title.length || c.name.canFind(r.title))
			&& (!r._class.length || _class.canFind(r._class))
			&& (!r.instance.length || instance.canFind(r.instance)))
		{
			c.isFloating = r.isFloating;
			Monitor m;
			//for(m = monitors; m && m.num != r.monitor; m = m.next){}
			//if(m)
			//	c.monitor = m;
		}
	}
	if(ch.res_class)
		XFree(ch.res_class);
	if(ch.res_name)
		XFree(ch.res_name);
}

void clearurgent(Client c){
	XWMHints* wmh = XGetWMHints(dpy, c.win);
	c.isUrgent = false;
	if(!wmh)
		return;
	wmh.flags &= ~XUrgencyHint;
	XSetWMHints(dpy, c.win, wmh);
	XFree(wmh);
}

void focus(Client c){
	if(!c || !c.isVisible)
		return;
	if(monitor.active && monitor.active != c)
		unfocus(monitor.active, false);
	if(c){
		if(c.monitor != monitor)
			monitor = c.monitor;
		if(c.isUrgent)
			clearurgent(c);
		grabbuttons(c, true);
		setfocus(c);
	}else{
		XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
		XDeleteProperty(dpy, root, net.windowActive);
	}
	foreach(si, ws; monitor.workspaces){
		foreach(w; ws.clients){
			if(w == c){
				monitor.workspaceActive = cast(int)si;
				ws.setFocus(w);
			}
		}
	}
	restack;
	if(c.isfullscreen)
		c.raise;
	foreach(m; monitors)
		m.draw;
	XSync(dpy, false);
	previousFocus = c;
}

long[4] getStrut(Client client){
	int actualFormat;
	ulong bytes, items, count;
	ubyte* data;
	Atom actualType, atom;
	if(XGetWindowProperty(dpy, client.win, net.strutPartial, 0, 12, false, XA_CARDINAL, &actualType, &actualFormat, &count, &bytes, &data) == Success && data){
		assert(actualType == XA_CARDINAL);
		assert(actualFormat == 32);
		assert(count == 12);
		auto array = (cast(CARDINAL*)data)[0..12];
		XFree(data);
		return array[0..4];
	}
	return [0,0,0,0];

}


Atom[] getPropList(Client c, Atom prop){
	int di;
	ulong dl;
	ubyte* p;
	Atom da;
	Atom[] atom;
	ulong count;
	if(XGetWindowProperty(dpy, c.win, prop, 0L, -1, false, XA_ATOM,
	                      &da, &di, &count, &dl, &p) == Success && p){
		atom = (cast(Atom*)p)[0..count].dup;
		XFree(p);
	}
	return atom;
}

Atom getatomprop(Client c, Atom prop){
	int di;
	ulong dl;
	ubyte* p;
	Atom da, atom = None;
	if(XGetWindowProperty(dpy, c.win, prop, 0L, atom.sizeof, false, XA_ATOM,
	                      &da, &di, &dl, &dl, &p) == Success && p){
		atom = *cast(Atom*)p;
		XFree(p);
	}
	return atom;
}

void grabbuttons(Client c, bool focused){
	updatenumlockmask();
	uint i, j;
	uint[] modifiers = [ 0, LockMask, numlockmask, numlockmask|LockMask ];
	XUngrabButton(dpy, AnyButton, AnyModifier, c.win);
	if(focused){
		for(i = 0; i < buttons.length; i++)
			for(j = 0; j < modifiers.length; j++)
				XGrabButton(dpy, buttons[i].button,
				            buttons[i].mask | modifiers[j],
				            c.win, false, BUTTONMASK,
				            GrabModeAsync, GrabModeSync, None, None);
	}
	else
		XGrabButton(dpy, AnyButton, AnyModifier, c.win, false,
		            BUTTONMASK, GrabModeAsync, GrabModeSync, None, None);
}


CARDINAL getprop(CARDINAL)(Window window, Atom atom){
	auto p = _rawget(window, atom, XA_CARDINAL);
	auto d = *(cast(CARDINAL*)p);
	XFree(p);
	return d;
}


ubyte* _rawget(Window window, Atom atom, int type, ulong count=1){
	int di;
	ulong dl;
	ubyte* p;
	Atom da;
	if(XGetWindowProperty(dpy, window, atom, 0L, count, false, type,
	                      &da, &di, &count, &dl, &p) == Success && p){
		return p;
	}
	throw new Exception("no data");
}

