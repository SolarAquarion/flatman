module dock.draw;

import dock;

__gshared:


enum DRW_FONT_CACHE_SIZE = 32;

auto BETWEEN(T)(T x, T min, T max){
	return x > min && x < max;
}

class Clr {

	ulong pix;
	XftColor rgb;

	this(string name, int screen){
		Colormap cmap = DefaultColormap(dpy, screen);
		Visual* vis = DefaultVisual(dpy, screen);
		if(!XftColorAllocName(dpy, vis, cmap, name.toStringz, &rgb))
			throw new Exception("Cannot allocate color " ~ name);
		pix = rgb.pixel;
	}

}

class Cur {
	Cursor cursor;
	this(int shape){
		cursor = XCreateFontCursor(dpy, shape);
	}
	void destroy(){
		XFreeCursor(dpy, cursor);
	}
}

struct ClrScheme {
	Clr* fg;
	Clr* bg;
	Clr* border;
}

class Font {

	int ascent;
	int descent;
	uint h;
	XftFont* xfont;
	FcPattern* pattern;

	this(int screen, string name){
		this(screen, name, null);
	}

	this(int screen, string name, FcPattern* pattern){
		if(!name.length && !pattern)
			throw new Exception("No font specified.");
		if(name.length){
			xfont = XftFontOpenName(dpy, screen, name.toStringz);
			pattern = FcNameParse(cast(FcChar8*)name);
			if(!xfont || !pattern){
				if(xfont){
					XftFontClose(dpy, xfont);
					xfont = null;
				}
				throw new Exception("Cannot load font " ~ name);
			}
		}else if(pattern){
			xfont = XftFontOpenPattern(dpy, pattern);
			if(!xfont)
				throw new Exception("Error, cannot load font pattern");
			else
				pattern = null;
		}
		ascent = xfont.ascent;
		descent = xfont.descent;
		h = ascent + descent;
	}

	int[2] size(string text){
		XGlyphInfo ext;
		if(!text.length)
			return [0,0];
		XftTextExtentsUtf8(dpy, xfont, cast(XftChar8*)text.toStringz, cast(int)text.length, &ext);
		return[ext.xOff, h];
	}

	int width(string text){
		return size(text)[0];
	}

	void destroy(){
		if(pattern)
			FcPatternDestroy(pattern);
		XftFontClose(dpy, xfont);
	}

}

class Draw {

	uint w, h;
	Display* dpy;
	int screen;
	x11.X.Window root;
	Drawable drawable;
	XftDraw* xft;
	GC gc;
	Clr color;
	Clr[string] colors;
	size_t fontcount;
	Font[] fonts;

	this(Display* dpy, int screen, x11.X.Window root, int w, int h){
		this.dpy = dpy;
		this.screen = screen;
		this.root = root;
		w = w;
		h = h;
		drawable = XCreatePixmap(dpy, root, w, h, DefaultDepth(dpy, screen));
		gc = XCreateGC(dpy, root, 0, null);
		fontcount = 0;
		XSetLineAttributes(dpy, gc, 1, LineSolid, CapButt, JoinMiter);
		auto cmap = DefaultColormap(dpy, screen);
		auto vis = DefaultVisual(dpy, screen);
		xft = XftDrawCreate(dpy, drawable, vis, cmap);
	}

	size_t width(string text){
		return fonts[0].width(text) + fonts[0].h;
	}

	void resize(int w, int h){
		this.w = w;
		this.h = h;
		if(drawable)
			XFreePixmap(dpy, drawable);
		drawable = XCreatePixmap(dpy, root, w, h, DefaultDepth(dpy, screen));
		XftDrawChange(xft, drawable);
	}

	void destroy(){
		foreach(font; fonts)
			font.destroy;
		XFreePixmap(dpy, drawable);
		XftDrawDestroy(xft);
		XFreeGC(dpy, gc);
	}

	void load_fonts(string[] fonts){
		foreach(name; fonts)
			this.fonts ~= new Font(screen, name);
	}

	void setColor(string name){
		if(name !in colors)
			colors[name] = new Clr(name, screen);
		color = colors[name];
	}

	void clip(int[2] pos, int[2] size){
		auto rect = XRectangle(cast(short)pos[0], cast(short)pos[1], cast(short)size[0], cast(short)size[1]);
		XftDrawSetClipRectangles(xft, 0, 0, &rect, 1);
		XSetClipRectangles(dpy, gc, 0, 0, &rect, 1, Unsorted);
	}

	void noclip(){
		XSetClipMask(dpy, gc, None);
		XftDrawSetClip(xft, null);
	}

	void rect(int[2] pos, int[2] size){
		XSetForeground(dpy, gc, color.pix);
		XFillRectangle(dpy, drawable, gc, pos.x, h-size.h-pos.y, size.w+1, size.h+1);
	}

	void rectOutline(int[2] pos, int[2] size){
		XSetForeground(dpy, gc, color.pix);
		XDrawRectangle(dpy, drawable, gc, pos.x+1, h-pos.y+1, size.w-1, size.h-1);
	}

	void text(string text, int[2] pos, double offset=-0.2){
		if(text.length){
			auto curfont = fonts[0];
			auto width = width(text);
			auto fontHeight = curfont.h;
			auto offsetRight = max(0.0,-offset)*fontHeight;
			auto offsetLeft = max(0.0,offset-1)*fontHeight;
			auto x = pos.x - min(1,max(0,offset))*width + offsetRight - offsetLeft;
			auto y = h - pos.y - 1;
			XftDrawStringUtf8(xft, &color.rgb, curfont.xfont, cast(int)x.lround, cast(int)y.lround, text.toStringz, cast(int)text.length);
		}
	}

	void map(x11.X.Window win, int x, int y, uint w, uint h){
		XCopyArea(dpy, drawable, win, gc, x, y, w, h, x, y);
		XSync(dpy, False);
	}


}

struct Extnts {
	uint w;
	uint h;
}
