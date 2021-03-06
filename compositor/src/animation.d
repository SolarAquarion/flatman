module composite.animation;


import composite;


class Animation {

	static double time;
	static update(){
		time = now;
	}

	double start;
	double end;
	double timeStart;
	double duration;
	double function(double) func;

	this(double value){
		this(value, value, 1);
	}

	this(double value, double function(double) func){
		this(value, value, 1, func);
	}

	this(double start, double end, double duration){
		this(start, end, duration, a => a);
	}

	this(double start, double end, double duration, double function(double) func){
		this.start = start;
		this.end = end;
		this.timeStart = time;
		this.duration = duration;
		this.func = func;
	}

	void change(double value){
		start = calculate;
		end = value;
		timeStart = time;
	}

	void change(double value, double duration){
		change(value);
		this.duration = duration;
	}

	void change(double value, double function(double) func){
		change(value);
		this.func = func;
	}

	void replace(double start, double end){
		this.start = start;
		this.end = end;
		timeStart = time;
	}

	void replace(double end){
		this.start = end;
		this.end = end;
		timeStart = time;
	}

	double completion(){
		if(done)
			return 1;
		return (time - timeStart).min(duration)/duration;
	}

	double calculate(){
		if(done)
			return end;
		return start + (end-start)*func(completion).min(1).max(0);

	}

	bool done(){
		return timeStart+duration < time;
	}

	double timeCurrent(){
		return time;
	}

}


