var score, sd, tempo;
var samples, samplesDir, noteData;

score = CtkScore();

sd = CtkSynthDef(\note, {
	|out = 0, buf, rate = 1.0, amp = 0.7|
	var snd;
	snd = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, doneAction: 2);
	snd = Decimator.ar(snd, 8000, 4);
	Out.ar(out, Pan2.ar(snd, 0.0, amp));
});

samplesDir = "xxx/tr505/";

samples = (
	bassdrum: "bass drum 505.wav",
	snare: "snare drum 505.wav",
	closedhihat: "closed hi-hat 505.wav",
	openhihat: "closed hi-hat 505.wav",
	handclap: "hand clap 505.wav",
	sidestick: "rim shot 505.wav"
);

samples.keys.do { |name|
	samples[name] = CtkBuffer(samplesDir +/+ samples[name]);
	score.add(samples[name]);
};

tempo = 60 / 120;

noteData = TabFileReader("xxxxx.notes");
noteData.do { |line|
	if (line[1] == "note") {
		var time = line[0].asFloat;
		var type = line[2].asSymbol;
		var note = sd.note(time*4*tempo).buf_(samples[type]);
		score.add(note);
	};
};

score.write("xxxxx.wav",
	sampleRate: 44100,
	headerFormat: "WAVE",
	sampleFormat: "float",
	options: ServerOptions.new.numOutputBusChannels_(2),
	action: {
		"Score successfully written.".postln;
		0.exit;
	}
);