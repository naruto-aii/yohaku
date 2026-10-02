(function () {
  var gardenApi = YohakuGarden;
  var items = window.YOHAKU_ITEMS;
  var KEY = "yohaku.preview.v2";
  var params = new URLSearchParams(location.search);
  var flow = params.get("flow");
  var root = document.getElementById("app");
  var picture = null;
  var kind = "plant";
  var nickname = "";
  var screen = "tutorial";
  var remaining = 25 * 60;
  var running = false;
  var phase = "focus";
  var tick = null;
  var focusMin = 25;
  var breakMin = 5;
  var unlocked = false;

  if (params.get("reset") === "1") localStorage.removeItem(KEY);

  var garden = gardenApi.createGarden(items, { state: loadState() });

  if (flow) applyFlow(flow);

  function loadState() {
    if (flow) return null;
    try {
      var raw = localStorage.getItem(KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (error) {
      return null;
    }
  }

  function save() {
    if (flow === "audit") return;
    localStorage.setItem(KEY, JSON.stringify(garden.state));
  }

  function applyFlow(name) {
    garden = gardenApi.createGarden(items);
    if (name === "tutorial" || name === "audit") {
      screen = "tutorial";
      return;
    }
    garden.pullTutorial();
    garden.pullTutorial();
    if (name === "prepare") {
      screen = "prepare";
      return;
    }
    if (name === "pull") {
      garden.state.dropUnits = 1000 * 3600;
      screen = "pull";
      return;
    }
    if (name === "packs") {
      screen = "packs";
      return;
    }
    if (name === "odds") {
      screen = "odds";
      kind = "plant";
      return;
    }
    if (name === "shelf") {
      garden.begin();
      garden.recordFocus((30 / 1.1) * 3600);
      garden.placeNamed("朝の一鉢");
      screen = "shelf";
      return;
    }
    if (name === "timer" || name === "grown") {
      garden.begin();
      garden.noteFocusBegan();
      if (name === "grown") {
        garden.recordFocus(60);
        garden.noteSessionEnded();
      }
      screen = "timer";
      remaining = name === "grown" ? 24 * 60 : 25 * 60;
      running = false;
      phase = "focus";
    }
  }

  function dropLabel() {
    return "しずく " + garden.dropText();
  }

  function imageTag(item, className) {
    var src = gardenApi.gachaImage(item);
    if (!src) {
      return '<div class="' + className + ' empty-art"><span>' + item.name + "</span></div>";
    }
    return '<img class="' + className + '" alt="' + item.name + '" src="' + src + '">';
  }

  function renderPair() {
    if (!garden.state.grow) return "";
    var plant = garden.find(garden.state.grow.plant, "plant");
    var pot = garden.find(garden.state.grow.pot, "pot");
    var progress = garden.displayProgress();
    var index = gardenApi.stageIndex(progress, garden.realProgress() >= 1);
    var flower = 22 + index * 5;
    var height = Math.round(flower / 0.51);
    var marks = "";
    for (var i = 0; i < 32; i++) marks += '<i class="' + (i < index ? "on" : "") + '"></i>';
    var plantSrc = gardenApi.gachaImage(plant);
    var potSrc = gardenApi.gachaImage(pot);
    var plantHtml = plantSrc
      ? '<img alt="' + plant.name + '" src="' + plantSrc + '" style="height:' + height + 'px">'
      : '<div class="stem" style="height:' + flower + 'px"></div><div class="stem-name">' + plant.name + "</div>";
    var potHtml = potSrc
      ? '<img class="pot-img" alt="' + pot.name + '" src="' + potSrc + '">'
      : '<div class="bowl"></div><div class="stem-name">' + pot.name + "</div>";
    return '<div class="pair" id="growing">' +
      '<div class="pair-plant">' + plantHtml + "</div>" +
      potHtml +
      '<div class="marks">' + marks + "</div>" +
      '<p class="pair-title">' + plant.name + "ー" + pot.name + "</p>" +
      '<p class="quiet">' + gardenApi.stageWord(index) + " " + index + "/32</p>" +
      "</div>";
  }

  function clock() {
    var total = Math.max(0, Math.ceil(remaining - 0.05));
    var m = String(Math.floor(total / 60)).padStart(2, "0");
    var s = String(total % 60).padStart(2, "0");
    return m + ":" + s;
  }

  function render() {
    var html = "";
    if (params.get("audit") === "1" && screen === "tutorial" && flow === "audit") {
      html = auditHtml();
    } else if (garden.state.tutorial !== "done" && screen !== "odds") {
      html = tutorialHtml();
    } else if (screen === "timer") {
      html = timerHtml();
    } else if (screen === "odds") {
      html = oddsHtml();
    } else if (screen === "pull") {
      html = pullHtml();
    } else if (screen === "shelf") {
      html = shelfHtml();
    } else if (screen === "packs") {
      html = packHtml();
    } else if (screen === "pay") {
      html = payHtml();
    } else {
      html = prepareHtml();
    }
    if (picture) html += pictureHtml(picture);
    root.innerHTML = html;
    bind();
    save();
  }

  function tutorialHtml() {
    var button = garden.state.tutorial === "plant" ? "植物を引く" : "鉢を引く";
    var line = garden.state.lastLines[0] ? '<p class="result">' + garden.state.lastLines[0] + "</p>" : "";
    return '<p class="mark">余白</p>' +
      '<p class="lead">はじめに、植物を一つ、鉢を一つ受け取ります。</p>' +
      '<p class="drops">' + dropLabel() + "</p>" +
      '<button class="wide" id="tutorial">' + button + "</button>" + line;
  }

  function prepareHtml() {
    var noises = [
      ["white", "白", false],
      ["pink", "ピンク", true],
      ["brown", "ブラウン", true],
      ["rain", "雨", true]
    ];
    var noise = noises.map(function (row) {
      var locked = row[2] && !unlocked;
      var on = garden.state.noise === row[0] ? " on" : "";
      return '<div><button class="dot' + on + '" data-noise="' + row[0] + '">' + (locked ? "·" : "") + "</button><div>" + row[1] + "</div></div>";
    }).join("");
    var heard = garden.state.lastLines.length === 1 ? '<p class="result">' + garden.state.lastLines[0] + "</p>" : "";
    var body = '<p class="mark">余白</p>' + heard + '<p class="label">音</p><div class="noise">' + noise + "</div>";
    if (!garden.state.grow && !garden.state.awaiting) {
      body += '<p class="label">育てる植物</p>' + choices("plant");
      body += '<p class="label">使う鉢</p>' + choices("pot");
      body += '<button class="wide" id="begin">始める</button>';
    } else if (garden.state.awaiting) {
      body += namingBlock();
    } else {
      body += '<p class="pair-title">' + garden.state.grow.plant + "ー" + garden.state.grow.pot + "</p>";
      body += '<button class="wide" id="continue">続ける</button>';
    }
    body += '<div class="links">' +
      link("odds", "出るもの") + link("pull", "引く") + link("shelf", "棚") +
      "</div><div class=\"links\">" + link("packs", "しずく") + link("pay", "設定") + "</div>";
    return body;
  }

  function choices(kindName) {
    var names = garden.owned(kindName);
    if (!names.length) return '<p class="quiet">空いているものがありません。</p>';
    return names.map(function (name) {
      var free = garden.freeCount(name, kindName);
      var selected = (kindName === "plant" ? garden.state.draftPlant : garden.state.draftPot) === name;
      return '<button class="choice' + (selected ? " on" : "") + '" data-kind="' + kindName + '" data-name="' + name + '" ' + (free ? "" : "disabled") + '>' +
        "<span>" + name + "</span><span>" + free + "</span></button>";
    }).join("");
  }

  function timerHtml() {
    var top = "";
    if (garden.state.grow) top = renderPair();
    else if (garden.state.awaiting) top = namingBlock();
    else top = '<p class="quiet">咲いた組み合わせは、棚にあります。</p>';
    return '<button class="back" id="back">戻る</button>' + top +
      '<p class="phase">' + (phase === "focus" ? "集中" : "休憩") + "</p>" +
      '<p class="clock" id="clock">' + clock() + "</p>" +
      '<button class="play" id="play">' + (running ? "一時停止" : "開始") + "</button>" +
      '<p class="drops bottom" id="drops">' + dropLabel() + "</p>";
  }

  function oddsHtml() {
    var list = (kind === "plant" ? garden.plants : garden.pots).map(function (item, index) {
      return '<button class="odd" data-index="' + index + '"><span>' + item.name + "</span><span>" + item.rarity + "</span><span>" + item.percent + "</span></button>";
    }).join("");
    return '<p class="title">出るもの</p><p class="quiet">枠の中の一つずつです。</p>' +
      '<div class="links"><button data-pool="plant">植物</button><button data-pool="pot">鉢</button></div>' +
      '<div class="odds" id="odds">' + list + "</div>" +
      '<button class="text" data-go="prepare">閉じる</button>';
  }

  function pullHtml() {
    var lines = garden.state.lastLines.map(function (line) { return "<p>" + line + "</p>"; }).join("");
    return '<p class="title">引く</p><div class="links"><button data-pool="plant">植物</button><button data-pool="pot">鉢</button></div>' +
      '<p class="drops">' + dropLabel() + "</p>" +
      '<button class="wide" id="once">引く</button>' +
      '<button class="wide" id="ten">10回引く</button>' +
      '<div class="results">' + lines + "</div>" +
      '<div class="links"><button data-go="odds">出るもの</button><button data-go="packs">しずく</button></div>' +
      '<button class="text" data-go="prepare">閉じる</button>';
  }

  function shelfHtml() {
    var naming = garden.state.awaiting ? namingBlock() : "";
    var growing = garden.state.grow ? renderPair() : "";
    var rows = garden.state.shelf.map(function (pair) {
      return '<div class="shelf-row"><p>' + pair.title + "</p>" + (pair.nickname ? "<p class=\"quiet\">" + pair.nickname + "</p>" : "") + "</div>";
    }).join("");
    if (!rows && !garden.state.awaiting) rows = '<p class="quiet">咲いた組み合わせは、ここに並びます。</p>';
    return '<p class="title">棚</p>' + naming + growing + rows + '<button class="text" data-go="prepare">閉じる</button>';
  }

  function packHtml() {
    var packs = [40, 150, 380, 1200, 2200, 5000].map(function (n) {
      return '<div class="pack"><span>' + n + '</span><span>価格は App Store で表示されます</span></div>';
    }).join("");
    return '<p class="title">しずく</p><p class="drops">' + garden.dropText() + "</p>" +
      '<p class="quiet">価格は App Store で表示されます。</p>' + packs +
      '<button class="text" data-go="prepare">閉じる</button>';
  }

  function payHtml() {
    return '<p class="title">余白をひらく</p>' +
      '<p class="quiet">ピンク、ブラウン、雨。集中と休憩の長さ。連続の保存。</p>' +
      '<p class="quiet">価格は App Store で表示されます。</p>' +
      '<p class="quiet">yohaku_lifetime</p>' +
      '<button class="text" data-go="prepare">閉じる</button>';
  }

  function namingBlock() {
    var waiting = garden.state.awaiting;
    return '<p class="pair-title">' + waiting.plant + "ー" + waiting.pot + "</p>" +
      '<input id="nick" placeholder="名前" value="' + nickname.replace(/"/g, "") + '">' +
      '<p class="quiet">空でも置けます。</p><button class="wide" id="place">棚に置く</button>';
  }

  function pictureHtml(item) {
    var src = gardenApi.gachaImage(item);
    var img = src ? '<img class="detail-img" alt="' + item.name + '" src="' + src + '">' : '<p class="quiet">絵のファイルはボード上の位置だけが残っています。</p>';
    var stand = item.standIn ? '<p class="quiet">差し替えの仮の平面イラスト</p>' : "";
    return '<div class="modal" id="modal"><div class="sheet"><p class="title">' + item.name + "</p><p>" + item.rarity + "  " + item.percent + "</p>" +
      img + stand + '<p class="quiet">' + item.picture + '</p><button class="text" id="close-pic">閉じる</button></div></div>';
  }

  function link(id, label) {
    return '<button data-go="' + id + '">' + label + "</button>";
  }

  function bind() {
    var tutorial = document.getElementById("tutorial");
    if (tutorial) tutorial.onclick = function () { garden.pullTutorial(); render(); };
    document.querySelectorAll("[data-go]").forEach(function (button) {
      button.onclick = function () { screen = button.getAttribute("data-go"); render(); };
    });
    document.querySelectorAll("[data-noise]").forEach(function (button) {
      button.onclick = function () {
        var picked = button.getAttribute("data-noise");
        if (picked !== "white" && !unlocked) { screen = "pay"; render(); return; }
        garden.state.noise = garden.state.noise === picked ? null : picked;
        render();
      };
    });
    document.querySelectorAll(".choice").forEach(function (button) {
      button.onclick = function () {
        var pickedKind = button.getAttribute("data-kind");
        var name = button.getAttribute("data-name");
        if (garden.freeCount(name, pickedKind) < 1) return;
        if (pickedKind === "plant") garden.state.draftPlant = name;
        else garden.state.draftPot = name;
        render();
      };
    });
    var begin = document.getElementById("begin");
    if (begin) begin.onclick = function () {
      if (!garden.begin()) return;
      if (!garden.state.noise) garden.state.noise = "white";
      garden.noteFocusBegan();
      remaining = focusMin * 60;
      phase = "focus";
      running = true;
      screen = "timer";
      startTick();
      render();
    };
    var cont = document.getElementById("continue");
    if (cont) cont.onclick = function () {
      if (!garden.state.noise) garden.state.noise = "white";
      garden.noteFocusBegan();
      screen = "timer";
      running = true;
      startTick();
      render();
    };
    var back = document.getElementById("back");
    if (back) back.onclick = function () { running = false; screen = "prepare"; render(); };
    var play = document.getElementById("play");
    if (play) play.onclick = function () {
      running = !running;
      if (running && phase === "focus") garden.noteFocusBegan();
      if (running) startTick();
      render();
    };
    var once = document.getElementById("once");
    if (once) once.onclick = function () { garden.pull(kind, 1); render(); };
    var ten = document.getElementById("ten");
    if (ten) ten.onclick = function () { garden.pull(kind, 10); render(); };
    document.querySelectorAll("[data-pool]").forEach(function (button) {
      button.onclick = function () { kind = button.getAttribute("data-pool"); render(); };
    });
    document.querySelectorAll(".odd").forEach(function (button) {
      button.onclick = function () {
        var list = kind === "plant" ? garden.plants : garden.pots;
        picture = list[Number(button.getAttribute("data-index"))];
        render();
      };
    });
    var close = document.getElementById("close-pic");
    if (close) close.onclick = function () { picture = null; render(); };
    var nick = document.getElementById("nick");
    if (nick) nick.oninput = function () { nickname = nick.value; };
    var place = document.getElementById("place");
    if (place) place.onclick = function () {
      garden.placeNamed(nickname);
      nickname = "";
      screen = "shelf";
      render();
    };
  }

  function startTick() {
    if (tick) return;
    tick = setInterval(function () {
      if (!running) return;
      remaining -= 1;
      if (phase === "focus") garden.recordFocus(1);
      if (remaining > 0) {
        var clockNode = document.getElementById("clock");
        var drops = document.getElementById("drops");
        if (drops) drops.textContent = dropLabel();
        if (clockNode) clockNode.textContent = clock();
        return;
      }
      if (phase === "focus") {
        garden.noteSessionEnded();
        phase = "rest";
        remaining = breakMin * 60;
      } else {
        phase = "focus";
        remaining = focusMin * 60;
        running = false;
      }
      render();
    }, 1000);
  }

  function auditHtml() {
    var report = gardenApi.audit(items);
    var rows = report.lines.map(function (line) {
      return '<li class="' + (line.indexOf("PASS") === 0 ? "pass" : "fail") + '">' + line + "</li>";
    }).join("");
    window.__yohakuAudit = report.ok ? "PASS" : "FAIL";
    return '<p class="title" id="audit-result">' + (report.ok ? "監査は通りました" : "監査に失敗しました") + "</p><ul class=\"audit\">" + rows + "</ul>";
  }

  if (!flow && location.hash) {
    var hashed = location.hash.replace("#", "");
    if (hashed) screen = hashed;
  }
  if (flow === "audit") screen = "tutorial";
  render();
  if (flow === "audit") {
    root.innerHTML = auditHtml();
  }
})();
