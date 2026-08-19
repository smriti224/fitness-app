import React, { useState, useMemo } from "react";
import { Home, UtensilsCrossed, Dumbbell, Scale, BarChart3, Plus, ChevronDown, Flame, Beef, Sun, Moon } from "lucide-react";
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

const LIGHT_COLORS = {
  bg: "#EDE4E0",
  surface: "#FFFFFF",
  surfaceAlt: "#F3EDE8",
  border: "#E3D8CF",
  text: "#665A48",
  textMuted: "#9F8772",
  accent: "#4C7A3D",
  accentDark: "#375C2C",
  onAccent: "#F2EDE6",
  rest: "#C8DBBE",
  accentTint: "rgba(76,122,61,0.16)",
  restTint: "rgba(200,219,190,0.6)",
};

const DARK_COLORS = {
  bg: "#050705",
  surface: "#0D110D",
  surfaceAlt: "#141A13",
  border: "#1F2E1D",
  text: "#E4F5E6",
  textMuted: "#6B8A6E",
  accent: "#39FF6A",
  accentDark: "#1FB854",
  onAccent: "#041008",
  rest: "#496653",
  accentTint: "rgba(57,255,106,0.14)",
  restTint: "rgba(73,102,83,0.26)",
};

const COLORS = { ...LIGHT_COLORS };

const SPLIT = {
  Monday: ["Incline dumbbell press", "Flat barbell bench press", "Seated dumbbell shoulder press", "Dumbbell lateral raises", "Rope pushdowns", "Cable tricep kickbacks"],
  Tuesday: ["Lat pulldown", "Seated cable row", "Straight-arm pulldown", "Face pulls", "Incline dumbbell curls", "Hammer curls"],
  Wednesday: ["Barbell squats", "Dumbbell RDLs", "Leg extensions", "Seated hamstring curls", "Standing calf raises"],
  Thursday: ["Lat pulldown", "Chest supported machine row", "Dumbbell lateral raises", "Reverse pec deck", "Face pulls"],
  Friday: ["Pec deck", "Dumbbell lateral raises", "Preacher curls", "Cable curls", "Rope pushdowns", "Overhead extensions"],
};

const PRESET_FOODS = [
  { name: "Oats", cal: 150, protein: 5 },
  { name: "Chicken breast", cal: 165, protein: 31 },
  { name: "Whey scoop", cal: 120, protein: 24 },
  { name: "Rice (1 cup)", cal: 200, protein: 4 },
  { name: "Paneer (100g)", cal: 265, protein: 18 },
];

const WEIGHT_HISTORY = [
  { date: "05 Aug", weight: 45.3 }, { date: "06 Aug", weight: 45.4 }, { date: "07 Aug", weight: 45.5 },
  { date: "08 Aug", weight: 45.1 }, { date: "09 Aug", weight: 44.9 }, { date: "10 Aug", weight: 45.5 },
  { date: "11 Aug", weight: 45.65 }, { date: "12 Aug", weight: 45.2 }, { date: "13 Aug", weight: 45.0 },
  { date: "14 Aug", weight: 45.2 }, { date: "15 Aug", weight: 45.35 }, { date: "16 Aug", weight: 45.45 },
];

const NUTRITION_HISTORY = [
  { date: "11 Aug", cal: 1750, protein: 82 }, { date: "12 Aug", cal: 1800, protein: 91 },
  { date: "13 Aug", cal: 1880, protein: 86 }, { date: "14 Aug", cal: 1890, protein: 74 },
  { date: "15 Aug", cal: 1889, protein: 66 }, { date: "16 Aug", cal: 1820, protein: 88 },
];

const WORKOUT_LOG_HISTORY = [
  { date: "11 Aug", day: "Monday", exercise: "Incline dumbbell press", weight: 10, reps: "9,8,8" },
  { date: "04 Aug", day: "Monday", exercise: "Incline dumbbell press", weight: 10, reps: "8,8,8" },
  { date: "13 Aug", day: "Wednesday", exercise: "Barbell squats", weight: 30, reps: "9,8,8" },
];

function todayStr() {
  const d = new Date(2026, 7, 16);
  return d.toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

function TabButton({ active, onClick, Icon, label }) {
  return (
    <button
      onClick={onClick}
      style={{
        flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 4,
        background: "none", border: "none", padding: "8px 0", cursor: "pointer",
        color: active ? COLORS.accent : COLORS.textMuted,
      }}
    >
      <Icon size={20} strokeWidth={active ? 2.4 : 1.8} />
      <span style={{ fontSize: 10, fontFamily: "Inter, sans-serif", fontWeight: active ? 600 : 400 }}>{label}</span>
    </button>
  );
}

function SubTabBar({ tabs, active, onChange }) {
  return (
    <div style={{ display: "flex", gap: 6, marginBottom: 16 }}>
      {tabs.map((t) => (
        <button
          key={t.key}
          onClick={() => onChange(t.key)}
          style={{
            padding: "6px 12px", borderRadius: 20, fontSize: 12, fontFamily: "Inter, sans-serif",
            border: `1px solid ${active === t.key ? COLORS.accent : COLORS.border}`,
            background: active === t.key ? COLORS.accentTint : "transparent",
            color: active === t.key ? COLORS.accent : COLORS.textMuted, cursor: "pointer",
          }}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}

function Card({ children, style }) {
  return (
    <div style={{ background: COLORS.surface, border: `1px solid ${COLORS.border}`, borderRadius: 14, padding: 14, ...style }}>
      {children}
    </div>
  );
}

function HomeTab({ foods, targetCal, targetProtein }) {
  const loggedDays = [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  const streak = 6;
  const daysInMonth = 31;
  const startWeekday = 6; // Aug 1 2026 is a Saturday

  const totals = foods.reduce((a, f) => ({ cal: a.cal + f.cal, protein: a.protein + f.protein }), { cal: 0, protein: 0 });
  const remainingCal = targetCal - totals.cal;
  const remainingProtein = targetProtein - totals.protein;

  const cells = [];
  for (let i = 0; i < startWeekday; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <Card>
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between" }}>
          <span style={{ fontSize: 12, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>Current streak</span>
        </div>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 8, marginTop: 6 }}>
          <Flame size={34} fill="#E8804A" color="#E8804A" strokeWidth={0} style={{ marginBottom: 2 }} />
          <span style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 44, fontWeight: 700, color: COLORS.accent, lineHeight: 1, textShadow: `0 0 18px ${COLORS.accent}55` }}>
            {streak}
          </span>
          <span style={{ fontSize: 13, color: COLORS.textMuted, marginBottom: 6, fontFamily: "Inter, sans-serif" }}>days</span>
        </div>
      </Card>

      <Card>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10 }}>
          <span style={{ fontSize: 13, fontWeight: 600, fontFamily: "Inter, sans-serif", color: COLORS.text }}>August 2026</span>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 4, fontSize: 10, color: COLORS.textMuted, marginBottom: 6, fontFamily: "Inter, sans-serif" }}>
          {["S", "M", "T", "W", "T", "F", "S"].map((d, i) => <div key={i} style={{ textAlign: "center" }}>{d}</div>)}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 4 }}>
          {cells.map((d, i) => {
            const isLogged = d && loggedDays.includes(d);
            const isSunday = d && (startWeekday + d - 1) % 7 === 0;
            const isToday = d === 16;
            let bg = "transparent";
            let color = d === null ? "transparent" : isToday ? COLORS.text : COLORS.textMuted;
            if (isLogged) { bg = COLORS.accentTint; color = COLORS.accent; }
            else if (isSunday) { bg = COLORS.restTint; color = COLORS.accentDark; }
            return (
              <div key={i} style={{
                aspectRatio: "1", display: "flex", alignItems: "center", justifyContent: "center",
                borderRadius: 8, fontSize: 11, fontFamily: "'IBM Plex Mono', monospace",
                background: bg, color,
                border: isToday ? `1px solid ${COLORS.accent}` : "none",
              }}>
                {d || ""}
              </div>
            );
          })}
        </div>
      </Card>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
        <Card style={{ padding: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, color: COLORS.textMuted, fontSize: 11, fontFamily: "Inter, sans-serif" }}>
            <Flame size={14} /> Calories today
          </div>
          <div style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 26, fontWeight: 700, marginTop: 4, color: COLORS.text }}>{totals.cal}</div>
          <div style={{ fontSize: 10, color: COLORS.accent, fontFamily: "Inter, sans-serif", marginTop: 2 }}>{remainingCal} left</div>
        </Card>
        <Card style={{ padding: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, color: COLORS.textMuted, fontSize: 11, fontFamily: "Inter, sans-serif" }}>
            <Beef size={14} /> Protein today
          </div>
          <div style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 26, fontWeight: 700, marginTop: 4, color: COLORS.text }}>{totals.protein}g</div>
          <div style={{ fontSize: 10, color: COLORS.accent, fontFamily: "Inter, sans-serif", marginTop: 2 }}>{remainingProtein}g left</div>
        </Card>
      </div>
    </div>
  );
}

function NutritionTab({ foods, setFoods, targetCal, setTargetCal, targetProtein, setTargetProtein }) {
  const [sub, setSub] = useState("log");
  const [name, setName] = useState("");
  const [cal, setCal] = useState("");
  const [protein, setProtein] = useState("");
  const [editingTarget, setEditingTarget] = useState(false);
  const [presets] = useState(PRESET_FOODS);

  const totals = foods.reduce((a, f) => ({ cal: a.cal + f.cal, protein: a.protein + f.protein }), { cal: 0, protein: 0 });
  const remainingCal = targetCal - totals.cal;
  const remainingProtein = targetProtein - totals.protein;

  function handleNameChange(v) {
    setName(v);
    const m = presets.find((p) => p.name.toLowerCase() === v.toLowerCase());
    if (m) { setCal(String(m.cal)); setProtein(String(m.protein)); }
  }

  function addFood() {
    if (!name.trim() || !cal || !protein) return;
    setFoods([...foods, { name: name.trim(), cal: Number(cal), protein: Number(protein) }]);
    setName(""); setCal(""); setProtein("");
  }

  return (
    <div>
      <SubTabBar
        tabs={[{ key: "log", label: "Log" }, { key: "presets", label: "Presets" }, { key: "history", label: "History" }]}
        active={sub} onChange={setSub}
      />

      {sub === "log" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Card>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: editingTarget ? 8 : 0 }}>
              <div style={{ fontSize: 12, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>Daily target</div>
              <button onClick={() => setEditingTarget(!editingTarget)} style={{ background: "none", border: "none", color: COLORS.accent, fontSize: 11, fontFamily: "Inter, sans-serif", cursor: "pointer" }}>
                {editingTarget ? "Done" : "Edit"}
              </button>
            </div>
            {editingTarget ? (
              <div style={{ display: "flex", gap: 8 }}>
                <input placeholder="Target cal" value={targetCal} onChange={(e) => setTargetCal(Number(e.target.value) || 0)} style={{ ...inputStyle(), flex: 1 }} />
                <input placeholder="Target protein" value={targetProtein} onChange={(e) => setTargetProtein(Number(e.target.value) || 0)} style={{ ...inputStyle(), flex: 1 }} />
              </div>
            ) : (
              <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6 }}>
                <div>
                  <div style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 22, fontWeight: 700, color: COLORS.accent }}>{remainingCal}</div>
                  <div style={{ fontSize: 10, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>kcal remaining</div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 22, fontWeight: 700, color: COLORS.accent }}>{remainingProtein}g</div>
                  <div style={{ fontSize: 10, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>protein remaining</div>
                </div>
              </div>
            )}
          </Card>

          <Card>
            <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>Add a food</div>
            <input placeholder="Food name" value={name} onChange={(e) => handleNameChange(e.target.value)}
              style={inputStyle()} list="preset-list" />
            <datalist id="preset-list">
              {presets.map((p) => <option key={p.name} value={p.name} />)}
            </datalist>
            <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
              <input placeholder="Calories" value={cal} onChange={(e) => setCal(e.target.value)} style={{ ...inputStyle(), flex: 1 }} />
              <input placeholder="Protein (g)" value={protein} onChange={(e) => setProtein(e.target.value)} style={{ ...inputStyle(), flex: 1 }} />
            </div>
            <button onClick={addFood} style={primaryBtn()}>
              <Plus size={14} style={{ marginRight: 4, verticalAlign: -2 }} /> Add
            </button>
          </Card>

          <Card>
            <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>Today - {todayStr()}</div>
            {foods.map((f, i) => (
              <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderTop: i > 0 ? `1px solid ${COLORS.border}` : "none", fontFamily: "'IBM Plex Mono', monospace", fontSize: 12 }}>
                <span style={{ color: COLORS.text }}>{f.name}</span>
                <span style={{ color: COLORS.textMuted }}>{f.cal} kcal · {f.protein}g</span>
              </div>
            ))}
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, paddingTop: 10, borderTop: `1px solid ${COLORS.accent}` }}>
              <span style={{ fontSize: 12, fontWeight: 600, fontFamily: "Inter, sans-serif", color: COLORS.text }}>Total</span>
              <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, color: COLORS.accent }}>{totals.cal} kcal · {totals.protein}g</span>
            </div>
          </Card>
        </div>
      )}

      {sub === "presets" && (
        <Card>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>Saved items</div>
          {presets.map((p, i) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderTop: i > 0 ? `1px solid ${COLORS.border}` : "none", fontFamily: "'IBM Plex Mono', monospace", fontSize: 12 }}>
              <span>{p.name}</span>
              <span style={{ color: COLORS.textMuted }}>{p.cal} kcal · {p.protein}g</span>
            </div>
          ))}
        </Card>
      )}

      {sub === "history" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {NUTRITION_HISTORY.slice().reverse().map((d, i) => (
            <Card key={i} style={{ padding: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ fontSize: 12, fontFamily: "Inter, sans-serif", color: COLORS.text }}>{d.date}</span>
                <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, color: COLORS.textMuted }}>{d.cal} kcal · {d.protein}g</span>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

function WorkoutTab() {
  const [sub, setSub] = useState("log");
  const [day, setDay] = useState("");
  const [exercise, setExercise] = useState("");
  const [weight, setWeight] = useState("");
  const [reps, setReps] = useState(["", "", ""]);
  const [suggestion, setSuggestion] = useState(null);
  const [groupByDay, setGroupByDay] = useState(false);

  function showSuggestion() {
    if (!exercise) return;
    setSuggestion(`Last time: 9,8,8 at ${weight || 10}kg. Try 10,8,8 today.`);
  }

  const grouped = useMemo(() => {
    if (!groupByDay) return null;
    const g = {};
    WORKOUT_LOG_HISTORY.forEach((w) => { g[w.day] = g[w.day] || []; g[w.day].push(w); });
    return g;
  }, [groupByDay]);

  return (
    <div>
      <SubTabBar
        tabs={[{ key: "log", label: "Log" }, { key: "history", label: "History" }, { key: "split", label: "Split" }]}
        active={sub} onChange={setSub}
      />

      {sub === "log" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Card>
            <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>{todayStr()}</div>
            <div style={{ position: "relative" }}>
              <select value={day} onChange={(e) => { setDay(e.target.value); setExercise(""); }} style={selectStyle()}>
                <option value="">Select day</option>
                {Object.keys(SPLIT).map((d) => <option key={d} value={d}>{d}</option>)}
              </select>
              <ChevronDown size={14} style={{ position: "absolute", right: 12, top: 12, color: COLORS.textMuted, pointerEvents: "none" }} />
            </div>
            {day && (
              <div style={{ position: "relative", marginTop: 8 }}>
                <select value={exercise} onChange={(e) => setExercise(e.target.value)} style={selectStyle()}>
                  <option value="">Select exercise</option>
                  {SPLIT[day].map((ex) => <option key={ex} value={ex}>{ex}</option>)}
                </select>
                <ChevronDown size={14} style={{ position: "absolute", right: 12, top: 12, color: COLORS.textMuted, pointerEvents: "none" }} />
              </div>
            )}
            {exercise && (
              <>
                <input placeholder="Weight (kg)" value={weight} onChange={(e) => setWeight(e.target.value)} style={{ ...inputStyle(), marginTop: 8 }} />
                <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
                  {reps.map((r, i) => (
                    <input key={i} placeholder={`Set ${i + 1}`} value={r}
                      onChange={(e) => { const nr = [...reps]; nr[i] = e.target.value; setReps(nr); }}
                      style={{ ...inputStyle(), flex: 1 }} />
                  ))}
                </div>
                <button onClick={showSuggestion} style={ghostBtn()}>Suggest target →</button>
                {suggestion && (
                  <div style={{ marginTop: 8, padding: 10, background: COLORS.accentTint, border: `1px solid ${COLORS.accent}`, borderRadius: 10, fontSize: 12, color: COLORS.accent, fontFamily: "Inter, sans-serif" }}>
                    {suggestion}
                  </div>
                )}
                <button style={primaryBtn()}>Save entry</button>
              </>
            )}
          </Card>
        </div>
      )}

      {sub === "history" && (
        <div>
          <button onClick={() => setGroupByDay(!groupByDay)} style={ghostBtn()}>
            {groupByDay ? "Ungroup" : "Group by day"}
          </button>
          <div style={{ marginTop: 10, display: "flex", flexDirection: "column", gap: 10 }}>
            {groupByDay
              ? Object.entries(grouped).map(([d, entries]) => (
                <div key={d}>
                  <div style={{ fontSize: 11, color: COLORS.accent, marginBottom: 6, fontFamily: "Inter, sans-serif", fontWeight: 600 }}>{d}</div>
                  {entries.map((e, i) => <WorkoutRow key={i} e={e} />)}
                </div>
              ))
              : WORKOUT_LOG_HISTORY.map((e, i) => <WorkoutRow key={i} e={e} />)
            }
          </div>
        </div>
      )}

      {sub === "split" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {Object.entries(SPLIT).map(([d, exs]) => (
            <Card key={d} style={{ padding: 12 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: COLORS.accent, marginBottom: 6, fontFamily: "Inter, sans-serif" }}>{d}</div>
              {exs.map((ex, i) => (
                <div key={i} style={{ fontSize: 12, color: COLORS.textMuted, padding: "4px 0", fontFamily: "'IBM Plex Mono', monospace" }}>{ex}</div>
              ))}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

function WorkoutRow({ e }) {
  return (
    <Card style={{ padding: 12 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
        <span style={{ fontSize: 12, fontFamily: "Inter, sans-serif", color: COLORS.text }}>{e.exercise}</span>
        <span style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>{e.date}</span>
      </div>
      <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontSize: 12, color: COLORS.textMuted }}>{e.weight}kg · {e.reps}</span>
    </Card>
  );
}

function WeightTab() {
  const [weight, setWeight] = useState("");
  const [editing, setEditing] = useState(false);
  const [logged, setLogged] = useState(null);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <Card>
        <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>{todayStr()}</div>
        {logged === null || editing ? (
          <>
            <input placeholder="Morning weight (kg)" value={weight} onChange={(e) => setWeight(e.target.value)} style={inputStyle()} />
            <button onClick={() => { if (weight) { setLogged(weight); setEditing(false); } }} style={primaryBtn()}>Save</button>
          </>
        ) : (
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 32, fontWeight: 700, color: COLORS.text }}>{logged} kg</span>
            <button onClick={() => setEditing(true)} style={{ ...ghostBtn(), width: "auto", padding: "6px 14px" }}>Edit</button>
          </div>
        )}
      </Card>

      <Card>
        <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>Previous days</div>
        {WEIGHT_HISTORY.slice().reverse().slice(0, 8).map((w, i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "7px 0", borderTop: i > 0 ? `1px solid ${COLORS.border}` : "none", fontFamily: "'IBM Plex Mono', monospace", fontSize: 12 }}>
            <span style={{ color: COLORS.textMuted }}>{w.date}</span>
            <span>{w.weight} kg</span>
          </div>
        ))}
      </Card>
    </div>
  );
}

function GraphsTab() {
  const avg7 = (WEIGHT_HISTORY.slice(-7).reduce((a, w) => a + w.weight, 0) / 7).toFixed(2);
  const avgCal = Math.round(NUTRITION_HISTORY.reduce((a, d) => a + d.cal, 0) / NUTRITION_HISTORY.length);
  const avgProtein = Math.round(NUTRITION_HISTORY.reduce((a, d) => a + d.protein, 0) / NUTRITION_HISTORY.length);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
        <Card style={{ padding: 12 }}>
          <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>7-day avg weight</div>
          <div style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 24, fontWeight: 700, color: COLORS.accent, marginTop: 4 }}>{avg7} kg</div>
        </Card>
        <Card style={{ padding: 12 }}>
          <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: "Inter, sans-serif" }}>Avg cal / protein</div>
          <div style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 24, fontWeight: 700, marginTop: 4, color: COLORS.text }}>{avgCal} · {avgProtein}g</div>
        </Card>
      </div>

      <Card>
        <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>Weight trend</div>
        <div style={{ height: 140 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={WEIGHT_HISTORY}>
              <CartesianGrid stroke={COLORS.border} strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="date" tick={{ fontSize: 9, fill: COLORS.textMuted }} axisLine={{ stroke: COLORS.border }} tickLine={false} interval={1} />
              <YAxis domain={["dataMin - 0.3", "dataMax + 0.3"]} tick={{ fontSize: 9, fill: COLORS.textMuted }} axisLine={false} tickLine={false} width={30} />
              <Tooltip contentStyle={{ background: COLORS.surfaceAlt, border: `1px solid ${COLORS.border}`, fontSize: 11 }} />
              <Line type="monotone" dataKey="weight" stroke={COLORS.accent} strokeWidth={2} dot={{ r: 2, fill: COLORS.accent }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <Card>
        <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8, fontFamily: "Inter, sans-serif" }}>Calories, last 6 days</div>
        <div style={{ height: 140 }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={NUTRITION_HISTORY}>
              <CartesianGrid stroke={COLORS.border} strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="date" tick={{ fontSize: 9, fill: COLORS.textMuted }} axisLine={{ stroke: COLORS.border }} tickLine={false} />
              <YAxis tick={{ fontSize: 9, fill: COLORS.textMuted }} axisLine={false} tickLine={false} width={34} />
              <Tooltip contentStyle={{ background: COLORS.surfaceAlt, border: `1px solid ${COLORS.border}`, fontSize: 11 }} />
              <Bar dataKey="cal" fill={COLORS.accentDark} radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
    </div>
  );
}

function inputStyle() {
  return {
    width: "100%", boxSizing: "border-box", background: COLORS.surfaceAlt, border: `1px solid ${COLORS.border}`,
    borderRadius: 9, padding: "9px 11px", color: COLORS.text, fontSize: 13, fontFamily: "Inter, sans-serif", outline: "none",
  };
}
function selectStyle() {
  return { ...inputStyle(), appearance: "none", cursor: "pointer" };
}
function primaryBtn() {
  return {
    width: "100%", marginTop: 10, padding: "10px 0", background: COLORS.accent, border: "none",
    borderRadius: 9, color: COLORS.onAccent, fontWeight: 600, fontSize: 13, fontFamily: "Inter, sans-serif", cursor: "pointer",
  };
}
function ghostBtn() {
  return {
    width: "100%", marginTop: 8, padding: "9px 0", background: "transparent", border: `1px solid ${COLORS.border}`,
    borderRadius: 9, color: COLORS.text, fontSize: 12, fontFamily: "Inter, sans-serif", cursor: "pointer",
  };
}

export default function AppMockup() {
  const [tab, setTab] = useState("home");
  const [mode, setMode] = useState("light");
  const [foods, setFoods] = useState([{ name: "Oats", cal: 150, protein: 5 }, { name: "Whey scoop", cal: 120, protein: 24 }]);
  const [targetCal, setTargetCal] = useState(1800);
  const [targetProtein, setTargetProtein] = useState(80);

  Object.assign(COLORS, mode === "dark" ? DARK_COLORS : LIGHT_COLORS);

  return (
    <div style={{ display: "flex", justifyContent: "center", padding: "24px 0", background: "#0A0A0B" }}>
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Barlow+Condensed:wght@600;700&family=IBM+Plex+Mono:wght@400;500&display=swap');`}</style>
      <div style={{
        width: 380, height: 720, background: COLORS.bg, borderRadius: 36, border: "8px solid #000",
        display: "flex", flexDirection: "column", overflow: "hidden", boxShadow: "0 20px 60px rgba(0,0,0,0.5)",
      }}>
        <div style={{ padding: "16px 18px 10px", borderBottom: `1px solid ${COLORS.border}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={{ fontFamily: "'Barlow Condensed', sans-serif", fontSize: 20, fontWeight: 700, color: COLORS.text, letterSpacing: 0.5 }}>
            FLEX
          </span>
          <button
            onClick={() => setMode(mode === "light" ? "dark" : "light")}
            aria-label="Toggle theme"
            style={{
              background: COLORS.surfaceAlt, border: `1px solid ${COLORS.border}`, borderRadius: 20,
              width: 32, height: 32, display: "flex", alignItems: "center", justifyContent: "center",
              cursor: "pointer", color: COLORS.accent,
            }}
          >
            {mode === "light" ? <Moon size={15} /> : <Sun size={15} />}
          </button>
        </div>
        <div style={{ flex: 1, overflowY: "auto", padding: 16 }}>
          {tab === "home" && <HomeTab foods={foods} targetCal={targetCal} targetProtein={targetProtein} />}
          {tab === "nutrition" && <NutritionTab foods={foods} setFoods={setFoods} targetCal={targetCal} setTargetCal={setTargetCal} targetProtein={targetProtein} setTargetProtein={setTargetProtein} />}
          {tab === "workout" && <WorkoutTab />}
          {tab === "weight" && <WeightTab />}
          {tab === "graphs" && <GraphsTab />}
        </div>
        <div style={{ display: "flex", borderTop: `1px solid ${COLORS.border}`, background: COLORS.surface }}>
          <TabButton active={tab === "home"} onClick={() => setTab("home")} Icon={Home} label="Home" />
          <TabButton active={tab === "nutrition"} onClick={() => setTab("nutrition")} Icon={UtensilsCrossed} label="Nutrition" />
          <TabButton active={tab === "workout"} onClick={() => setTab("workout")} Icon={Dumbbell} label="Workout" />
          <TabButton active={tab === "weight"} onClick={() => setTab("weight")} Icon={Scale} label="Weight" />
          <TabButton active={tab === "graphs"} onClick={() => setTab("graphs")} Icon={BarChart3} label="Graphs" />
        </div>
      </div>
    </div>
  );
}
