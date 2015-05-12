var lilydrumCache, mode, readDir;
var score, sd, tempo;
var eventTypes;
var kits, kit, kitsDir, noteData;

// Read the .json cache file
lilydrumCache = JSONFileReader.read(Platform.userHomeDir +/+ ".lilydrum-cache");

kits = Dictionary();

// For reading a single kit (directory of samples)
readDir = { |name, dir, json|
	kits[name] = Dictionary();
	json["samples"].keysValuesDo { |samplename, file|
		kits[name][samplename.asSymbol] = dir +/+ file;
	};
};

kitsDir = lilydrumCache["kitsDir"];
if (File.exists(kitsDir +/+ "lilydrum.json")) {
	// Single directory
	var json = JSONFileReader.read(kitsDir +/+ "lilydrum.json");
	mode = \single;
	readDir.value(\main, kitsDir, json);
} {
	// Multiple directories
	mode = \multiple;
	PathName(kitsDir).folders.do { |dir|
		dir = dir.fullPath;
		if (File.exists(dir +/+ "lilydrum.json")) {
			var json = JSONFileReader.read(dir +/+ "lilydrum.json");
			readDir.value(json["name"].asSymbol, dir, json);
		};
	};
};

score = CtkScore();

sd = CtkSynthDef(\note, {
	|out = 0, buf, rate = 1.0, amp = 0.7|
	var snd;
	snd = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, doneAction: 2);
	//snd = Decimator.ar(snd, 8000, 4);
	Out.ar(out, Pan2.ar(snd, 0.0, amp));
});

// Convert the sample filenames into CtkBuffers
kits.values.do { |kit|
	kit.keys.do { |sample|
		kit[sample] = CtkBuffer(kit[sample]);
		score.add(kit[sample]);
	}
};

kit = \main;

tempo = 60 / 120;

// A list of event types in order of when we want to read them
// So when there are simultaneous lilydrum and note events, the lilydrum event is read first.
eventTypes = [\lilydrum, \note];

// Get the lilydrum note data
noteData = TabFileReader(lilydrumCache["notesFile"]).as(List);
// Convert times to floats (and event types to symbols) for simplicity
noteData.do { |row|
	row[0] = row[0].asFloat;
	row[1] = row[1].asSymbol;
};
// Sort the data first by time, then by event type
// This is the only way I know of for doing multi-sorts in SuperCollider
noteData.sort { |a, b|
	(a[0] < b[0]) or: { a[0] == b[0] and: {
		(eventTypes.indexOf(a[1]) ?? inf) <
		(eventTypes.indexOf(b[1]) ?? inf)
	} }
};

noteData.do { |line|
	line[1].switch
	{ \lilydrum } {
		var text = line[2];
		if (text.beginsWith("kit: ")) {
			kit = text[5..].asSymbol;
		}
	}
	{ \note } {
		var time = line[0];
		var type = line[2].asSymbol;
		var note = sd.note(time*4*tempo).buf_(kits[kit][type]);
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