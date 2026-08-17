from datetime import date as date_cls, timedelta

from flask import Flask, jsonify, request
from flask_cors import CORS

from models import FoodLog, FoodPreset, Settings, SplitExercise, WeightLog, WorkoutLog, db

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///tracker.db"
db.init_app(app)
CORS(app)  # lets the Flutter app call this from a different origin

with app.app_context():
    db.create_all()
    if not Settings.query.first():
        db.session.add(Settings(target_calories=1800, target_protein=80))
        db.session.commit()


# ---------------------------------------------------------------------------
# SPLIT  (the rarely-edited "what exercises belong to which day" sub-tab)
# ---------------------------------------------------------------------------

@app.route("/api/split", methods=["GET"])
def get_split():
    """Returns { "Monday": ["Incline dumbbell press", ...], "Tuesday": [...] }"""
    rows = SplitExercise.query.order_by(SplitExercise.day, SplitExercise.order).all()
    result = {}
    for r in rows:
        result.setdefault(r.day, []).append(r.exercise)
    return jsonify(result)


@app.route("/api/split/<day>", methods=["GET"])
def get_split_day(day):
    """Returns just one day's exercise list - this is what feeds the Workout tab's dropdown."""
    rows = SplitExercise.query.filter_by(day=day).order_by(SplitExercise.order).all()
    return jsonify([r.exercise for r in rows])


@app.route("/api/split", methods=["POST"])
def update_split():
    """Body: { "day": "Monday", "exercises": ["Ex1", "Ex2", ...] } - replaces that day's list."""
    data = request.json
    day = data["day"]
    SplitExercise.query.filter_by(day=day).delete()
    for i, ex in enumerate(data["exercises"]):
        db.session.add(SplitExercise(day=day, exercise=ex, order=i))
    db.session.commit()
    return jsonify({"status": "saved"})


# ---------------------------------------------------------------------------
# WORKOUTS
# ---------------------------------------------------------------------------

@app.route("/api/workouts", methods=["POST"])
def add_workout():
    """Body: { date, day, exercise, weight, set1, set2, set3, notes }"""
    data = request.json
    w = WorkoutLog(
        date=data["date"],
        day=data["day"],
        exercise=data["exercise"],
        weight=data.get("weight"),
        set1=str(data.get("set1", "")),
        set2=str(data.get("set2", "")),
        set3=str(data.get("set3", "")),
        notes=data.get("notes", ""),
    )
    db.session.add(w)
    db.session.commit()
    return jsonify({"id": w.id, "status": "saved"})


@app.route("/api/workouts", methods=["GET"])
def get_workouts():
    """Optional ?day=Monday or ?exercise=... query params for filtering/grouping."""
    day = request.args.get("day")
    exercise = request.args.get("exercise")
    q = WorkoutLog.query
    if day:
        q = q.filter_by(day=day)
    if exercise:
        q = q.filter_by(exercise=exercise)
    rows = q.order_by(WorkoutLog.date.desc()).all()
    return jsonify(
        [
            {
                "id": r.id, "date": r.date, "day": r.day, "exercise": r.exercise,
                "weight": r.weight, "set1": r.set1, "set2": r.set2, "set3": r.set3, "notes": r.notes,
            }
            for r in rows
        ]
    )


@app.route("/api/workouts/last", methods=["GET"])
def last_workout():
    """?exercise=... - the most recent logged entry for that exercise, for the 'Suggest target' button."""
    exercise = request.args.get("exercise")
    r = WorkoutLog.query.filter_by(exercise=exercise).order_by(WorkoutLog.date.desc()).first()
    if not r:
        return jsonify(None)
    return jsonify({"date": r.date, "weight": r.weight, "set1": r.set1, "set2": r.set2, "set3": r.set3})


# ---------------------------------------------------------------------------
# WEIGHT
# ---------------------------------------------------------------------------

@app.route("/api/weight", methods=["POST"])
def log_weight():
    """Body: { date, weight } - once per day, but re-posting the same date overwrites it (editable)."""
    data = request.json
    existing = WeightLog.query.filter_by(date=data["date"]).first()
    if existing:
        existing.weight = data["weight"]
    else:
        db.session.add(WeightLog(date=data["date"], weight=data["weight"]))
    db.session.commit()
    return jsonify({"status": "saved"})


@app.route("/api/weight", methods=["GET"])
def get_weights():
    rows = WeightLog.query.order_by(WeightLog.date.desc()).all()
    return jsonify([{"date": r.date, "weight": r.weight} for r in rows])


@app.route("/api/weight/average", methods=["GET"])
def weight_average():
    """7-day rolling average of the most recent 7 entries - null if fewer than 7 exist yet."""
    rows = WeightLog.query.order_by(WeightLog.date.desc()).limit(7).all()
    if len(rows) < 7:
        return jsonify({"average": None})
    avg = sum(r.weight for r in rows) / 7
    return jsonify({"average": round(avg, 2)})


# ---------------------------------------------------------------------------
# NUTRITION
# ---------------------------------------------------------------------------

@app.route("/api/foods/presets", methods=["GET"])
def get_presets():
    rows = FoodPreset.query.all()
    return jsonify([{"name": r.name, "calories": r.calories, "protein": r.protein} for r in rows])


@app.route("/api/foods/presets", methods=["POST"])
def add_preset():
    """Body: { name, calories, protein } - saved once, reused via autofill later."""
    data = request.json
    db.session.add(FoodPreset(name=data["name"], calories=data["calories"], protein=data["protein"]))
    db.session.commit()
    return jsonify({"status": "saved"})


@app.route("/api/foods", methods=["POST"])
def log_food():
    """Body: { date, name, calories, protein } - one entry in the day's running food list."""
    data = request.json
    f = FoodLog(date=data["date"], name=data["name"], calories=data["calories"], protein=data["protein"])
    db.session.add(f)
    db.session.commit()
    return jsonify({"id": f.id, "status": "saved"})


@app.route("/api/foods", methods=["GET"])
def get_foods():
    """?date=YYYY-MM-DD to get one day's food list, or omit to get everything (History sub-tab)."""
    date_param = request.args.get("date")
    q = FoodLog.query
    if date_param:
        q = q.filter_by(date=date_param)
    rows = q.order_by(FoodLog.id).all()
    return jsonify(
        [{"id": r.id, "date": r.date, "name": r.name, "calories": r.calories, "protein": r.protein} for r in rows]
    )


# ---------------------------------------------------------------------------
# TARGETS
# ---------------------------------------------------------------------------

@app.route("/api/targets", methods=["GET"])
def get_targets():
    s = Settings.query.first()
    return jsonify({"target_calories": s.target_calories, "target_protein": s.target_protein})


@app.route("/api/targets", methods=["POST"])
def set_targets():
    """Body: { target_calories, target_protein }"""
    data = request.json
    s = Settings.query.first()
    s.target_calories = data["target_calories"]
    s.target_protein = data["target_protein"]
    db.session.commit()
    return jsonify({"status": "saved"})


# ---------------------------------------------------------------------------
# HOME  (one combined endpoint for everything the Home tab needs)
# ---------------------------------------------------------------------------

@app.route("/api/home", methods=["GET"])
def home_summary():
    today = date_cls.today().isoformat()

    workout_dates = {r.date for r in WorkoutLog.query.all()}

    # streak: walk backward from today; a day counts if you logged a workout,
    # or if it's a Sunday (your rest day) so rest days don't break the streak
    streak = 0
    d = date_cls.today()
    while True:
        iso = d.isoformat()
        if iso in workout_dates or d.weekday() == 6:  # Monday=0 ... Sunday=6
            streak += 1
            d -= timedelta(days=1)
        else:
            break

    today_foods = FoodLog.query.filter_by(date=today).all()
    cal = sum(f.calories for f in today_foods)
    protein = sum(f.protein for f in today_foods)
    s = Settings.query.first()

    return jsonify(
        {
            "logged_days": sorted(workout_dates),
            "streak": streak,
            "today_calories": cal,
            "today_protein": protein,
            "target_calories": s.target_calories,
            "target_protein": s.target_protein,
            "remaining_calories": s.target_calories - cal,
            "remaining_protein": s.target_protein - protein,
        }
    )


if __name__ == "__main__":
    # host="0.0.0.0" so your phone can reach this over your home wifi, not just the computer itself
    app.run(debug=True, host="0.0.0.0", port=5000)
