module flatman.x.properties;


import flatman;

long getstate(Window w){
	int format;
	long result = -1;
	ubyte* p = null;
	ulong n, extra;
	Atom _real;
	if(XGetWindowProperty(dpy, w, wm.state, 0L, 2L, false, wm.state,
	                      &_real, &format, &n, &extra, cast(ubyte**)&p) != 0)
		return -1;
	if(n != 0)
		result = *p;
	XFree(p);
	return result;
}

bool gettextprop(Window w, Atom atom, ref string text){
	char** list;
	int n;
	XTextProperty name;
	XGetTextProperty(dpy, w, &name, atom);
	if(!name.nitems)
		return false;
	if(name.encoding == XA_STRING){
		text = to!string(*name.value);
	}else{
		if(XmbTextPropertyToTextList(dpy, &name, &list, &n) >= XErrorCode.Success && n > 0 && *list){
			text = (*list).to!string;
			XFreeStringList(list);
		}
	}
	XFree(name.value);
	return true;
}


alias CARDINAL = long;


void change(Window window, Atom atom, Atom[] data, int mode){
	XChangeProperty(dpy, window, atom, XA_ATOM, 32, mode, cast(ubyte*)data.ptr, cast(int)data.length);
	
}

void change(Window window, Atom atom, CARDINAL[] data, int mode){
	XChangeProperty(dpy, window, atom, XA_CARDINAL, 32, mode, cast(ubyte*)data.ptr, cast(int)data.length);
	
}

void change(Window window, Atom atom, CARDINAL data, int mode){
	XChangeProperty(dpy, window, atom, XA_CARDINAL, 32, mode, cast(ubyte*)&data, 1);
	
}

void change(Window window, Atom atom, string data, int mode){
	XChangeProperty(dpy, window, atom, XInternAtom(dpy, "UTF8_STRING", False), 8, mode, cast(ubyte*)data.toStringz, cast(int)data.length);
	
}

void change(Window window, Atom atom, Window data, int mode){
	XChangeProperty(dpy, window, atom, XA_WINDOW, 32, mode, cast(ubyte*)&data, 1);
	
}

void change(Window window, Atom atom, Client[] clients, int mode){
	Window[] data;
	foreach(c; clients)
		data ~= c.win;
	XChangeProperty(dpy, window, atom, XA_WINDOW, 32, mode, cast(ubyte*)data.ptr, cast(int)data.length);
	
}

void replace(T)(Window window, Atom atom, T data){
	change(window, atom, data, PropModeReplace);
}

void append(T)(Window window, Atom atom, T data){
	change(window, atom, data, PropModeAppend);
}

void remove(Window window, Atom atom){
	XDeleteProperty(dpy, window, atom);
}

void append(T)(Atom atom, T data){
	replace(root, atom, data);
}

void replace(T)(Atom atom, T data){
	replace(root, atom, data);
}

void remove(Atom atom){
	remove(root, atom);
}
