class_name GameState
extends RefCounted

const MIRACLE_IDS: Array[StringName] = [&"oasis", &"rain", &"banish_shadow", &"call_soul", &"shape"]
const RACE_IDS: Array[StringName] = [&"human", &"forestfolk", &"stoneborn", &"wildfolk"]

var daylight: BigNum
var sap: BigNum
var growth: BigNum
var memory: BigNum
var faith: BigNum
var leaf_level: int = 0
var branch_level: int = 0
var root_depth: int = 0
var tick: int = 0
var hope: int = 1
var races: Dictionary = {}
var relics_found: Array[int] = []
var totem_interpreted: Array[int] = []
var insight: int = 0
var relations: Dictionary = {}
var relation_events: Array[StringName] = []
var chloroplast_level: int = 0
var xylem_level: int = 0
var sunflower_level: int = 0
var nautilus_level: int = 0
var root_eff_level: int = 0
var plundered: Dictionary = {}
var plunder_reveals: Array[StringName] = []
var intimate_events: Array[StringName] = []
var choices_done: Array[StringName] = []
var truth: int = 0
var drift_extra: float = 0.0
var race_memory_eff: Dictionary = {}
var choice_flags: Array[StringName] = []
var storyteller_stories: Array[StringName] = []
var soul_river: int = 100   # 河底灵魂存量（守恒：河底 + 已复活 = 100 恒，M5f）
var run_number: int = 1                # 当前周目（M6，1 起始；周目门控/文本层叠依据）
var ending_seen: Array[StringName] = []  # 已达成结局 id（bad/normal/good/true，M6）
var pending_ending: Dictionary = {}      # 尚未完成结算的终局快照（支持退出后恢复）
var seedling_level: int = 0     # 嫩叶教学链（M5d2）
var firepit_level: int = 0       # 说书人火塘·人族设施（M5d2）
var ring_level: int = 0          # 歌之环·林地民设施（M5d2）
var forge_level: int = 0         # 铸根坊·石裔设施（M5d2）
var totem_pole_level: int = 0    # 图腾柱·野民设施（M5d2）
var deep_dream: bool = false     # 深根梦已购（一次性，M5d2）
var wind_veil: bool = false      # 风语膜已购（一次性，M5d2）
var faith_engine_level: int = 0     # 信仰引擎（M5e）
var memory_engine_level: int = 0    # 记忆引擎（M5e）
var lingua_life_level: int = 0      # 生命之语等级（M5e）
var lingua_memory_level: int = 0    # 记忆之语等级（M5e，批 2 升）
var lingua_nodes: Array[StringName] = []  # 已购树语节点（M5e）
var realm_echoes: Array[StringName] = []  # 已抵达九界；知识余烬，跨周目保留（M6-D）
var miracle_counts: Dictionary = {}  # 本周目各奇迹成功施展次数（M6-D）
var miracle_rain_ticks: int = 0  # 唤雨剩余人口结算次数（M6-D）
var miracle_cleansed_races: Array[StringName] = []  # 驱影暂时解除冻结的种族（M6-D）
var last_saved_unix: int = 0       # 离线结算时间戳；0 表示旧档或尚未保存

func _init() -> void:
    daylight = BigNum.new(0.0)
    sap = BigNum.new(0.0)
    growth = BigNum.new(0.0)
    memory = BigNum.new(0.0)
    faith = BigNum.new(0.0)

func to_dict() -> Dictionary:
    return {
        "daylight": daylight.to_dict(),
        "sap": sap.to_dict(),
        "growth": growth.to_dict(),
        "memory": memory.to_dict(),
        "faith": faith.to_dict(),
        "leaf_level": leaf_level,
        "branch_level": branch_level,
        "root_depth": root_depth,
        "tick": tick,
        "hope": hope,
        "races": races,
        "relics_found": relics_found,
        "totem_interpreted": totem_interpreted,
        "insight": insight,
        "relations": relations,
        "relation_events": relation_events,
        "plundered": plundered,
        "plunder_reveals": plunder_reveals,
        "intimate_events": intimate_events,
        "choices_done": choices_done,
        "truth": truth,
        "drift_extra": drift_extra,
        "race_memory_eff": race_memory_eff,
        "choice_flags": choice_flags,
        "storyteller_stories": storyteller_stories,
        "faith_engine_level": faith_engine_level,
        "memory_engine_level": memory_engine_level,
        "lingua_life_level": lingua_life_level,
        "lingua_memory_level": lingua_memory_level,
        "lingua_nodes": lingua_nodes,
        "realm_echoes": realm_echoes,
        "miracle_counts": miracle_counts,
        "miracle_rain_ticks": miracle_rain_ticks,
        "miracle_cleansed_races": miracle_cleansed_races,
        "last_saved_unix": last_saved_unix,
        "soul_river": soul_river,
        "run_number": run_number,
        "ending_seen": ending_seen,
        "pending_ending": pending_ending,
        "chloroplast_level": chloroplast_level,
        "xylem_level": xylem_level,
        "sunflower_level": sunflower_level,
        "nautilus_level": nautilus_level,
        "root_eff_level": root_eff_level,
        "seedling_level": seedling_level,
        "firepit_level": firepit_level,
        "ring_level": ring_level,
        "forge_level": forge_level,
        "totem_pole_level": totem_pole_level,
        "deep_dream": deep_dream,
        "wind_veil": wind_veil,
    }

static func from_dict(d: Dictionary) -> GameState:
    var s := GameState.new()
    s.daylight = BigNum.from_dict(d.get("daylight", {}))
    s.sap = BigNum.from_dict(d.get("sap", {}))
    s.growth = BigNum.from_dict(d.get("growth", {}))
    s.memory = BigNum.from_dict(d.get("memory", {}))
    s.faith = BigNum.from_dict(d.get("faith", {}))
    s.leaf_level = int(d.get("leaf_level", 0))
    s.branch_level = int(d.get("branch_level", 0))
    s.root_depth = int(d.get("root_depth", 0))
    s.tick = int(d.get("tick", 0))
    s.hope = int(d.get("hope", 1))
    # M2 旧档迁移：无 races 但有 human_awakened —— 迁移人族状态
    var rd: Variant = d.get("races", {})
    if typeof(rd) != TYPE_DICTIONARY:
        rd = {}
    if rd.is_empty() and d.has("human_awakened"):
        rd = {"human": {"awakened": bool(d.get("human_awakened", false)),
                "population": 50.0 if bool(d.get("human_awakened", false)) else 0.0}}
    s.races = {}
    for race_id: Variant in rd:
        var entry: Variant = rd[race_id]
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        s.races[race_id] = {
            "awakened": bool(entry.get("awakened", false)),
            "population": float(entry.get("population", 0.0)),
        }
    var rf: Array = d.get("relics_found", [])
    var cleaned: Array = []
    for x in rf:
        if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT:
            cleaned.append(int(x))
    s.relics_found.assign(cleaned)
    var ti: Array = d.get("totem_interpreted", [])
    var ti_cleaned: Array = []
    for x in ti:
        if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT:
            ti_cleaned.append(int(x))
    s.totem_interpreted.assign(ti_cleaned)
    s.insight = int(d.get("insight", 0))
    var rel: Variant = d.get("relations", {})
    if typeof(rel) != TYPE_DICTIONARY:
        rel = {}
    s.relations = {}
    for rid: Variant in rel:
        var rv: Variant = rel[rid]
        if typeof(rv) == TYPE_INT or typeof(rv) == TYPE_FLOAT:
            s.relations[rid] = clampf(float(rv), RelationActions.RELATION_MIN, RelationActions.RELATION_MAX)
    var re: Array = d.get("relation_events", [])
    var re_cleaned: Array = []
    for x in re:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            re_cleaned.append(StringName(x))
    s.relation_events.assign(re_cleaned)
    var pl: Variant = d.get("plundered", {})
    if typeof(pl) != TYPE_DICTIONARY:
        pl = {}
    s.plundered = {}
    for pid: Variant in pl:
        var pv: Variant = pl[pid]
        if typeof(pv) == TYPE_INT or typeof(pv) == TYPE_FLOAT:
            s.plundered[pid] = int(pv)
    var pr: Array = d.get("plunder_reveals", [])
    var pr_cleaned: Array = []
    for x in pr:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            pr_cleaned.append(StringName(x))
    s.plunder_reveals.assign(pr_cleaned)
    var ie: Array = d.get("intimate_events", [])
    var ie_cleaned: Array = []
    for x in ie:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            ie_cleaned.append(StringName(x))
    s.intimate_events.assign(ie_cleaned)
    var cd: Array = d.get("choices_done", [])
    var cd_cleaned: Array = []
    for x in cd:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            cd_cleaned.append(StringName(x))
    s.choices_done.assign(cd_cleaned)
    var tv: Variant = d.get("truth", 0)
    s.truth = int(tv) if typeof(tv) == TYPE_INT or typeof(tv) == TYPE_FLOAT else 0
    var dv: Variant = d.get("drift_extra", 0.0)
    s.drift_extra = float(dv) if typeof(dv) == TYPE_INT or typeof(dv) == TYPE_FLOAT else 0.0
    var rme: Variant = d.get("race_memory_eff", {})
    if typeof(rme) != TYPE_DICTIONARY:
        rme = {}
    s.race_memory_eff = {}
    for rid2: Variant in rme:
        var rv2: Variant = rme[rid2]
        if typeof(rv2) == TYPE_INT or typeof(rv2) == TYPE_FLOAT:
            s.race_memory_eff[rid2] = float(rv2)
    var cf: Array = d.get("choice_flags", [])
    var cf_cleaned: Array = []
    for x in cf:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            cf_cleaned.append(StringName(x))
    s.choice_flags.assign(cf_cleaned)
    var stories: Variant = d.get("storyteller_stories", [])
    if typeof(stories) != TYPE_ARRAY:
        stories = []
    var stories_cleaned: Array = []
    for x in stories:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            stories_cleaned.append(StringName(x))
    s.storyteller_stories.assign(stories_cleaned)
    s.chloroplast_level = int(d.get("chloroplast_level", 0))
    s.xylem_level = int(d.get("xylem_level", 0))
    s.sunflower_level = int(d.get("sunflower_level", 0))
    s.nautilus_level = int(d.get("nautilus_level", 0))
    s.root_eff_level = int(d.get("root_eff_level", 0))
    var sr: Variant = d.get("soul_river", 100)
    if typeof(sr) == TYPE_INT or typeof(sr) == TYPE_FLOAT:
        s.soul_river = clampi(int(sr), 0, SoulActions.RIVER_TOTAL)
    else:
        s.soul_river = 100  # 损坏防御（同 relations 防御模式）
    s.run_number = int(d.get("run_number", 1))
    var es: Array = d.get("ending_seen", [])
    var es_cleaned: Array = []
    for x in es:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            es_cleaned.append(StringName(x))
    s.ending_seen.assign(es_cleaned)
    s.pending_ending = _sanitize_pending_ending(d.get("pending_ending", {}))
    # M6 已发布旧档迁移：world_axis 已结算却没有终局快照时，恢复到可继续的界面。
    if s.pending_ending.is_empty() and s.choices_done.has(&"world_axis"):
        var legacy_intent := &""
        for flag: StringName in s.choice_flags:
            var flag_text := str(flag)
            if flag_text.begins_with("world_axis_intent_"):
                legacy_intent = StringName(flag_text.trim_prefix("world_axis_intent_"))
        if legacy_intent != &"" and not s.ending_seen.is_empty():
            var legacy_outcome: StringName = s.ending_seen[-1]
            s.pending_ending = {
                "outcome": legacy_outcome,
                "intent": legacy_intent,
                "hope_before": maxi(s.hope - 1, 0) if legacy_outcome == &"good" else s.hope,
                "phase": &"return" if legacy_intent == &"return" else &"settlement",
                "return_step": 1 if legacy_intent == &"return" else 0,
                "return_halted": false,
            }
    var sl: Variant = d.get("seedling_level", 0)
    s.seedling_level = int(sl) if typeof(sl) == TYPE_INT or typeof(sl) == TYPE_FLOAT else 0
    var fpl: Variant = d.get("firepit_level", 0)
    s.firepit_level = int(fpl) if typeof(fpl) == TYPE_INT or typeof(fpl) == TYPE_FLOAT else 0
    var rl: Variant = d.get("ring_level", 0)
    s.ring_level = int(rl) if typeof(rl) == TYPE_INT or typeof(rl) == TYPE_FLOAT else 0
    var fgl: Variant = d.get("forge_level", 0)
    s.forge_level = int(fgl) if typeof(fgl) == TYPE_INT or typeof(fgl) == TYPE_FLOAT else 0
    var tpl: Variant = d.get("totem_pole_level", 0)
    s.totem_pole_level = int(tpl) if typeof(tpl) == TYPE_INT or typeof(tpl) == TYPE_FLOAT else 0
    var dd: Variant = d.get("deep_dream", false)
    s.deep_dream = bool(dd) if typeof(dd) == TYPE_BOOL else false
    var wv: Variant = d.get("wind_veil", false)
    s.wind_veil = bool(wv) if typeof(wv) == TYPE_BOOL else false
    var fel: Variant = d.get("faith_engine_level", 0)
    s.faith_engine_level = int(fel) if typeof(fel) == TYPE_INT or typeof(fel) == TYPE_FLOAT else 0
    var mel: Variant = d.get("memory_engine_level", 0)
    s.memory_engine_level = int(mel) if typeof(mel) == TYPE_INT or typeof(mel) == TYPE_FLOAT else 0
    var lll: Variant = d.get("lingua_life_level", 0)
    s.lingua_life_level = int(lll) if typeof(lll) == TYPE_INT or typeof(lll) == TYPE_FLOAT else 0
    var lml: Variant = d.get("lingua_memory_level", 0)
    s.lingua_memory_level = int(lml) if typeof(lml) == TYPE_INT or typeof(lml) == TYPE_FLOAT else 0
    var ln: Array = d.get("lingua_nodes", [])
    var ln_cleaned: Array = []
    for x in ln:
        if typeof(x) == TYPE_STRING or typeof(x) == TYPE_STRING_NAME:
            ln_cleaned.append(StringName(x))
    s.lingua_nodes.assign(ln_cleaned)
    var realm_raw: Variant = d.get("realm_echoes", [])
    if typeof(realm_raw) != TYPE_ARRAY:
        realm_raw = []
    var realm_cleaned: Array[StringName] = []
    for x: Variant in realm_raw:
        if typeof(x) != TYPE_STRING and typeof(x) != TYPE_STRING_NAME:
            continue
        var realm_id := StringName(str(x))
        if RealmCatalog.is_known(realm_id) and not realm_cleaned.has(realm_id):
            realm_cleaned.append(realm_id)
    s.realm_echoes.assign(realm_cleaned)
    var miracle_counts_raw: Variant = d.get("miracle_counts", {})
    if typeof(miracle_counts_raw) != TYPE_DICTIONARY:
        miracle_counts_raw = {}
    s.miracle_counts = {}
    for raw_id: Variant in miracle_counts_raw:
        if typeof(raw_id) != TYPE_STRING and typeof(raw_id) != TYPE_STRING_NAME:
            continue
        var miracle_id := StringName(str(raw_id))
        if not MIRACLE_IDS.has(miracle_id):
            continue
        var raw_count: Variant = miracle_counts_raw[raw_id]
        if typeof(raw_count) != TYPE_INT and typeof(raw_count) != TYPE_FLOAT:
            continue
        var count := maxi(int(raw_count), 0)
        if miracle_id == &"oasis" or miracle_id == &"shape":
            count = mini(count, 3)
        s.miracle_counts[miracle_id] = count
    var rain_ticks_raw: Variant = d.get("miracle_rain_ticks", 0)
    s.miracle_rain_ticks = clampi(int(rain_ticks_raw), 0, 120) if typeof(rain_ticks_raw) == TYPE_INT or typeof(rain_ticks_raw) == TYPE_FLOAT else 0
    var cleansed_raw: Variant = d.get("miracle_cleansed_races", [])
    if typeof(cleansed_raw) != TYPE_ARRAY:
        cleansed_raw = []
    var cleansed: Array[StringName] = []
    for raw_race_id: Variant in cleansed_raw:
        if typeof(raw_race_id) != TYPE_STRING and typeof(raw_race_id) != TYPE_STRING_NAME:
            continue
        var race_id := StringName(str(raw_race_id))
        if RACE_IDS.has(race_id) and not cleansed.has(race_id):
            cleansed.append(race_id)
    s.miracle_cleansed_races.assign(cleansed)
    var saved_at: Variant = d.get("last_saved_unix", 0)
    s.last_saved_unix = maxi(int(saved_at), 0) if typeof(saved_at) == TYPE_INT or typeof(saved_at) == TYPE_FLOAT else 0
    return s

static func _sanitize_pending_ending(raw: Variant) -> Dictionary:
    if typeof(raw) != TYPE_DICTIONARY:
        return {}
    var data: Dictionary = raw
    var outcome := StringName(str(data.get("outcome", "")))
    var intent := StringName(str(data.get("intent", "")))
    var phase := StringName(str(data.get("phase", "")))
    if not [&"bad", &"normal", &"good", &"true"].has(outcome):
        return {}
    if not [&"condense", &"refuse", &"return", &"self"].has(intent):
        return {}
    if phase != &"return" and phase != &"settlement":
        return {}
    var hope_before_raw: Variant = data.get("hope_before", 1)
    var step_raw: Variant = data.get("return_step", 0)
    var halted_raw: Variant = data.get("return_halted", false)
    return {
        "outcome": outcome,
        "intent": intent,
        "hope_before": maxi(int(hope_before_raw), 0) if typeof(hope_before_raw) == TYPE_INT or typeof(hope_before_raw) == TYPE_FLOAT else 1,
        "phase": phase,
        "return_step": clampi(int(step_raw), 0, ReturnSequence.STEPS) if typeof(step_raw) == TYPE_INT or typeof(step_raw) == TYPE_FLOAT else 0,
        "return_halted": bool(halted_raw) if typeof(halted_raw) == TYPE_BOOL else false,
    }

# M6 周目重置：新建一局的 GameState，仅拷贝跨周目保留字段（记忆余烬）
static func new_run_preserved(prev: GameState) -> GameState:
    var s := GameState.new()
    # 保留：希望 / 领悟 / 真相 / 知识解锁标记
    s.hope = prev.hope
    s.insight = prev.insight
    s.truth = prev.truth
    s.run_number = prev.run_number + 1
    s.ending_seen.assign(prev.ending_seen)
    s.choice_flags.assign(prev.choice_flags)          # 知识型 flag 保留
    s.totem_interpreted.assign(prev.totem_interpreted)
    s.storyteller_stories.assign(prev.storyteller_stories)
    s.realm_echoes.assign(prev.realm_echoes)
    return s
