var lilydrumCache, mode, readDir;
var score, sd, tempo;
var kits, kitsDir, noteData;

lilydrumCache = JSONFileReader.read(Platform.userHomeDir +/+ ".lilydrum-cache");

kits = Dictionary();

readDir = { |name, dir, json|
	kits[name] = Dictionary();
	json["kits"].keysValuesDo { |samplename, file|
		kits[name][samplename.asSymbol] = file;
	};
};

kitsDir = lilydrumCache["kitsDir"];
if (PathName(kitsDir +/+ "lilydrum.json").isFile) {
	var json = JSONFileReader.read(kitsDir +/+ "lilydrum.json");
	mode = \single;
	readDir.value(\main, kitsDir, json);
} {
	mode = \multiple;
	PathName(kitsDir).folders.do { |dir|
		dir = dir.fullPath;
		if (PathName(dir +/+ "lilydrum.json").isFile) {
			var json = JSONFileReader.read(dir +/+ "lilydrum.json");
			readDir.value(json["name"], dir, json);
		};
	};
};

score = CtkScore();

sd = CtkSynthDef(\note, {
	|out = 0, buf, rate = 1.0, amp = 0.7|
	var snd;
	snd = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, doneAction: 2);
	snd = Decimator.ar(snd, 8000, 4);
	Out.ar(out, Pan2.ar(snd, 0.0, amp));
});

kits.values.do { |kit|
	kit.keys.do { |sample|
		kit[sample] = CtkBuffer(kit[sample]);
		score.add(kit[sample]);
	}
};

kit = \main;

tempo = 60 / 120;

noteData = TabFileReader(lilydrumCache["notesFile"]);
noteData.do { |line|
	if (line[1] == "note") {
		var time = line[0].asFloat;
		var type = line[2].asSymbol;
		var note = sd.note(time*4*tempo).buf_(kits[type]);
		score.add(note);
	};
};

score.write(lilydrumCache["outFile"],
	sampleRate: 44100,
	headerFormat: "WAVE",
	sampleFormat: "float",
	options: ServerOptions.new.numOutputBusChannels_(2),
	action: {
		"Score successfully written.".postln;
		0.exit;
	}
);