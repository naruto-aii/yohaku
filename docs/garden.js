(function (root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.YohakuGarden = factory();
})(typeof self !== "undefined" ? self : this, function () {
  var UNITS = 3600;
  var HOURS = { N: 30, R: 50, SR: 100, SSR: 200 };
  var MULT = { N: 1.1, R: 1.2, SR: 1.3, SSR: 1.5 };

  function rollRarity(unit) {
    if (unit < 0.75) return "N";
    if (unit < 0.95) return "R";
    if (unit < 0.995) return "SR";
    return "SSR";
  }

  function hourText(value) {
    if (Math.abs(value - Math.round(value)) < 0.001) return String(Math.round(value));
    return (Math.round(value * 1000) / 1000).toFixed(3).replace(/0+$/, "").replace(/\.$/, "");
  }

  function stageIndex(display, bloomed) {
    if (bloomed) return 32;
    var clamped = Math.min(0.999, Math.max(0, display));
    return Math.min(31, Math.floor(clamped * 32));
  }

  function stageWord(index) {
    if (index >= 32) return "咲";
    if (index < 6) return "土";
    if (index < 13) return "芽";
    if (index < 21) return "葉";
    if (index < 28) return "蕾";
    return "花";
  }

  function gachaImage(item) {
    if (item.art) return "../catalog/art/" + item.art;
    if (item.kind === "pot" && item.crop) return "../catalog/crops/" + item.crop;
    return null;
  }

  function createGarden(items, options) {
    options = options || {};
    var random = options.random || Math.random;
    var plants = items.filter(function (item) { return item.kind === "plant"; });
    var pots = items.filter(function (item) { return item.kind === "pot"; });
    var state = options.state || {
      plantCounts: {},
      potCounts: {},
      grow: null,
      awaiting: null,
      shelf: [],
      dropUnits: 200 * UNITS,
      pendingHours: 0,
      tutorial: "plant",
      focusRemainder: 0,
      lastLines: [],
      draftPlant: "蒲公英",
      draftPot: "丸",
      noise: null
    };

    function find(name, kind) {
      var list = kind === "plant" ? plants : pots;
      for (var i = 0; i < list.length; i++) if (list[i].name === name) return list[i];
      return null;
    }

    function count(name, kind) {
      var bag = kind === "plant" ? state.plantCounts : state.potCounts;
      return bag[name] || 0;
    }

    function reserved(name, kind) {
      var n = 0;
      state.shelf.forEach(function (pair) {
        if ((kind === "plant" ? pair.plant : pair.pot) === name) n += 1;
      });
      if (state.grow && (kind === "plant" ? state.grow.plant : state.grow.pot) === name) n += 1;
      if (state.awaiting && (kind === "plant" ? state.awaiting.plant : state.awaiting.pot) === name) n += 1;
      return n;
    }

    function freeCount(name, kind) {
      return Math.max(0, count(name, kind) - reserved(name, kind));
    }

    function required(plantName, potName) {
      var plant = find(plantName, "plant");
      var pot = find(potName, "pot");
      return HOURS[plant.rarity] / MULT[pot.rarity];
    }

    function applyHours(hours) {
      if (!state.grow) {
        state.pendingHours += hours;
        return;
      }
      state.grow.hours += hours;
      var need = required(state.grow.plant, state.grow.pot);
      if (state.grow.hours + 1e-9 < need) return;
      var extra = state.grow.hours - need;
      state.awaiting = { plant: state.grow.plant, pot: state.grow.pot, nickname: "" };
      state.grow = null;
      if (extra > 0.0001) state.pendingHours += extra;
    }

    function receive(item) {
      var held = count(item.name, item.kind);
      var bag = item.kind === "plant" ? state.plantCounts : state.potCounts;
      if (held >= 80) {
        var added = HOURS[item.rarity] / 80;
        if (state.grow) applyHours(added);
        else state.pendingHours += added;
        return "所持が80の" + item.name + "です。数は増やさず、育ちの時間に " + hourText(added) + " 時間足しました。";
      }
      bag[item.name] = held + 1;
      return item.name + "を受け取りました。";
    }

    function spend(drops) {
      var cost = drops * UNITS;
      if (state.dropUnits < cost) return false;
      state.dropUnits -= cost;
      return true;
    }

    function pullTutorial() {
      if (state.tutorial === "plant") {
        if (!spend(100)) return;
        state.lastLines = [receive(find("蒲公英", "plant"))];
        state.tutorial = "pot";
        state.draftPlant = "蒲公英";
      } else if (state.tutorial === "pot") {
        if (!spend(100)) return;
        state.lastLines = [receive(find("丸", "pot"))];
        state.tutorial = "done";
        state.draftPot = "丸";
      }
    }

    function roll(kind) {
      var rarity = rollRarity(random());
      var pool = (kind === "plant" ? plants : pots).filter(function (item) { return item.rarity === rarity; });
      var index = Math.min(pool.length - 1, Math.floor(random() * pool.length));
      return pool[Math.max(0, index)];
    }

    function pull(kind, times) {
      if (state.tutorial !== "done") return;
      if (times !== 1 && times !== 10) return;
      if (!spend(times === 10 ? 1000 : 100)) return;
      var lines = [];
      for (var i = 0; i < times; i++) lines.push(receive(roll(kind)));
      state.lastLines = lines;
    }

    function recordFocus(seconds) {
      if (seconds <= 0) return;
      state.focusRemainder += seconds * 100;
      var units = Math.floor(state.focusRemainder + 1e-7);
      if (units > 0) {
        state.focusRemainder -= units;
        state.dropUnits += units;
      }
      var hours = seconds / 3600;
      if (state.grow) applyHours(hours);
      else state.pendingHours += hours;
    }

    function realProgress() {
      if (!state.grow) return 0;
      return Math.min(1, state.grow.hours / required(state.grow.plant, state.grow.pot));
    }

    function displayProgress() {
      if (!state.grow) return state.awaiting ? 1 : 0;
      var real = realProgress();
      if (real >= 1) return 1;
      return Math.min(0.99, Math.max(real, state.grow.visualFloor || 0));
    }

    function noteFocusBegan() {
      if (!state.grow) return;
      var real = realProgress();
      state.grow.visualAtStart = Math.min(0.99, Math.max(real, state.grow.visualFloor || 0));
    }

    function noteSessionEnded() {
      if (!state.grow) return;
      var real = realProgress();
      if (real >= 1) return;
      var before = Math.min(0.99, Math.max(real, state.grow.visualFloor || 0));
      var index = stageIndex(before, false);
      var nextStage = (index + 1) / 32;
      state.grow.visualFloor = Math.min(0.99, Math.max(before + 0.02, nextStage));
    }

    function canBegin() {
      return state.tutorial === "done" && !state.grow && !state.awaiting
        && freeCount(state.draftPlant, "plant") > 0
        && freeCount(state.draftPot, "pot") > 0;
    }

    function begin() {
      if (!canBegin()) return false;
      state.grow = {
        plant: state.draftPlant,
        pot: state.draftPot,
        hours: 0,
        visualFloor: 0,
        visualAtStart: 0
      };
      var banked = state.pendingHours;
      state.pendingHours = 0;
      if (banked > 0) applyHours(banked);
      return true;
    }

    function placeNamed(nickname) {
      if (!state.awaiting) return;
      var title = state.awaiting.plant + "ー" + state.awaiting.pot;
      state.shelf.unshift({
        plant: state.awaiting.plant,
        pot: state.awaiting.pot,
        nickname: String(nickname || "").trim(),
        title: title
      });
      state.awaiting = null;
    }

    function dropText() {
      var value = state.dropUnits / UNITS;
      if (Math.abs(value - Math.round(value)) < 0.0001) return String(Math.round(value));
      return value.toFixed(1);
    }

    function owned(kind) {
      return (kind === "plant" ? plants : pots).map(function (item) { return item.name; })
        .filter(function (name) { return count(name, kind) > 0; });
    }

    return {
      state: state,
      plants: plants,
      pots: pots,
      find: find,
      count: count,
      freeCount: freeCount,
      pullTutorial: pullTutorial,
      pull: pull,
      recordFocus: recordFocus,
      begin: begin,
      canBegin: canBegin,
      placeNamed: placeNamed,
      dropText: dropText,
      displayProgress: displayProgress,
      realProgress: realProgress,
      noteFocusBegan: noteFocusBegan,
      noteSessionEnded: noteSessionEnded,
      required: required,
      owned: owned,
      roll: roll
    };
  }

  function audit(items) {
    var lines = [];
    function check(name, ok) {
      lines.push((ok ? "PASS " : "FAIL ") + name);
      return ok;
    }
    var ok = true;
    var plants = items.filter(function (item) { return item.kind === "plant"; });
    var pots = items.filter(function (item) { return item.kind === "pot"; });
    var names = {};
    items.forEach(function (item) { names[item.name] = (names[item.name] || 0) + 1; });
    ok = check("160 items", items.length === 160) && ok;
    ok = check("80 plants and 80 pots", plants.length === 80 && pots.length === 80) && ok;
    ok = check("unique names", Object.keys(names).length === 160 && Object.keys(names).every(function (key) { return names[key] === 1; })) && ok;
    ok = check("no 薄い菊", !names["薄い菊"]) && ok;
    ["plant", "pot"].forEach(function (kind) {
      var list = kind === "plant" ? plants : pots;
      ok = check(kind + " N40 R24 SR12 SSR4",
        list.filter(function (i) { return i.rarity === "N"; }).length === 40 &&
        list.filter(function (i) { return i.rarity === "R"; }).length === 24 &&
        list.filter(function (i) { return i.rarity === "SR"; }).length === 12 &&
        list.filter(function (i) { return i.rarity === "SSR"; }).length === 4) && ok;
    });
    ok = check("first plant is 蒲公英", plants[0] && plants[0].name === "蒲公英" && plants[0].art === "plant-n-tampopo.png") && ok;
    ok = check("蒲公英 percent", plants[0].percent === "1.875%") && ok;
    ok = check("丸 exists", pots.some(function (item) { return item.name === "丸" && item.rarity === "N"; })) && ok;
    var nCount = plants.filter(function (item) { return item.rarity === "N" && item.percent === "1.875%"; }).length;
    var rCount = plants.filter(function (item) { return item.rarity === "R" && item.percent === "0.833%"; }).length;
    var srCount = plants.filter(function (item) { return item.rarity === "SR" && item.percent === "0.375%"; }).length;
    var ssrCount = plants.filter(function (item) { return item.rarity === "SSR" && item.percent === "0.125%"; }).length;
    ok = check("per-item percents", nCount === 40 && rCount === 24 && srCount === 12 && ssrCount === 4) && ok;

    var tutorial = createGarden(items, { random: function () { return 0; } });
    ok = check("starts with 200", tutorial.dropText() === "200") && ok;
    tutorial.pullTutorial();
    tutorial.pullTutorial();
    ok = check("tutorial names", tutorial.count("蒲公英", "plant") === 1 && tutorial.count("丸", "pot") === 1) && ok;
    ok = check("tutorial spends 200", tutorial.dropText() === "0" && tutorial.state.tutorial === "done") && ok;
    ok = check("no other starters", tutorial.owned("plant").length === 1 && tutorial.owned("pot").length === 1) && ok;

    var ten = createGarden(items, { random: function () { return 0; } });
    ten.state.tutorial = "done";
    ten.state.dropUnits = 1000 * UNITS;
    ten.pull("plant", 10);
    ok = check("10-pull costs 1000", ten.dropText() === "0") && ok;
    ok = check("10-pull returns 10 catalog names", ten.state.lastLines.length === 10 && ten.state.lastLines.every(function (line) {
      return plants.some(function (item) { return line.indexOf(item.name) === 0; });
    })) && ok;

    var cap = createGarden(items, { random: function () { return 0; } });
    cap.state.tutorial = "done";
    cap.state.dropUnits = 100 * UNITS;
    cap.state.plantCounts["蒲公英"] = 80;
    cap.pull("plant", 1);
    ok = check("81st does not raise count", cap.count("蒲公英", "plant") === 80) && ok;
    ok = check("81st adds time", cap.state.lastLines[0].indexOf("所持が80の蒲公英") === 0 && cap.state.pendingHours === 0.375) && ok;

    var grow = createGarden(items, { random: function () { return 0; } });
    grow.pullTutorial();
    grow.pullTutorial();
    ok = check("can begin", grow.begin()) && ok;
    var before = stageIndex(grow.displayProgress(), false);
    grow.noteFocusBegan();
    grow.recordFocus(1);
    grow.noteSessionEnded();
    var after = stageIndex(grow.displayProgress(), false);
    ok = check("short session advances the picture", after > before && grow.realProgress() < 1) && ok;
    ok = check("required hours", Math.abs(grow.required("蒲公英", "丸") - (30 / 1.1)) < 1e-9) && ok;

    var fresh = createGarden(items);
    fresh.state.dropUnits = 0;
    fresh.recordFocus(25 * 60);
    ok = check("25 minutes is 41.7 drops", fresh.dropText() === "41.7") && ok;
    var hour = createGarden(items);
    hour.state.dropUnits = 0;
    hour.recordFocus(3600);
    ok = check("60 minutes is 100 drops", hour.dropText() === "100") && ok;

    grow.recordFocus(30 / 1.1 * 3600);
    ok = check("bloom waits for a name", !!grow.state.awaiting && grow.state.awaiting.plant === "蒲公英") && ok;
    grow.placeNamed("朝の一鉢");
    ok = check("shelf title", grow.state.shelf[0].title === "蒲公英ー丸" && grow.state.shelf[0].nickname === "朝の一鉢") && ok;
    ok = check("long dash", grow.state.shelf[0].title.indexOf("ー") > 0) && ok;

    return { ok: ok, lines: lines };
  }

  return {
    createGarden: createGarden,
    audit: audit,
    gachaImage: gachaImage,
    stageIndex: stageIndex,
    stageWord: stageWord,
    hourText: hourText,
    rollRarity: rollRarity
  };
});
