from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class SplitExercise(db.Model):
    """Which exercises belong to which day - the rarely-edited split."""
    __tablename__ = "split_exercises"
    id = db.Column(db.Integer, primary_key=True)
    day = db.Column(db.String(10), nullable=False)       # "Monday" .. "Friday"
    exercise = db.Column(db.String(100), nullable=False)
    order = db.Column(db.Integer, default=0)              # keeps the exercise list in order


class WorkoutLog(db.Model):
    """One row per exercise per session - your actual logged results."""
    __tablename__ = "workout_logs"
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.String(10), nullable=False)       # "YYYY-MM-DD"
    day = db.Column(db.String(10), nullable=False)
    exercise = db.Column(db.String(100), nullable=False)
    weight = db.Column(db.Float, nullable=True)
    set1 = db.Column(db.String(20))
    set2 = db.Column(db.String(20))
    set3 = db.Column(db.String(20))
    notes = db.Column(db.String(300))


class WeightLog(db.Model):
    """One entry per day - morning weight."""
    __tablename__ = "weight_logs"
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.String(10), unique=True, nullable=False)
    weight = db.Column(db.Float, nullable=False)


class FoodPreset(db.Model):
    """Saved food items - typing a matching name autofills calories/protein.
    base_grams is the portion the calories/protein are for (e.g. 100g of yoghurt = 100 kcal),
    so logging a different gram amount can scale proportionally."""
    __tablename__ = "food_presets"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    calories = db.Column(db.Integer, nullable=False)
    protein = db.Column(db.Float, nullable=False)
    base_grams = db.Column(db.Integer, nullable=False, default=100)


class FoodLog(db.Model):
    """One row per food you log - no meal-type labels, just a running list per day.
    grams is optional and purely informational - it is never summed into daily totals."""
    __tablename__ = "food_logs"
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.String(10), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    calories = db.Column(db.Integer, nullable=False)
    protein = db.Column(db.Float, nullable=False)
    grams = db.Column(db.Integer, nullable=True)


class Settings(db.Model):
    """Single-row table holding your daily calorie/protein targets."""
    __tablename__ = "settings"
    id = db.Column(db.Integer, primary_key=True)
    target_calories = db.Column(db.Integer, default=1800)
    target_protein = db.Column(db.Float, default=80)
