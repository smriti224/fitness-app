# Lean Bulk Tracker - Backend

## Where this goes
Put `app.py`, `models.py`, and `requirements.txt` in the same folder on your computer -
e.g. `~/lean-bulk-tracker/backend/`. That's the whole backend.

## First-time setup
Open a terminal in that folder and run:

```
python3 -m venv venv
source venv/bin/activate        # on Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## Running it
```
python3 app.py
```

You should see something like:
```
* Running on http://127.0.0.1:5000
* Running on http://192.168.x.x:5000
```

The first time you run it, a `tracker.db` file (SQLite database) is created automatically
in that same folder - that's where all your data actually lives.

## Testing it works
While it's running, open a new terminal tab and try:
```
curl http://127.0.0.1:5000/api/split
```
You should get back `{}` (empty, since you haven't added your split yet) rather than an error.

## Connecting from your phone (Flutter app)
Your phone and computer need to be on the **same wifi network**. Use the
`192.168.x.x` address (not `127.0.0.1`) as the base URL in the Flutter app -
`127.0.0.1` on your phone would mean "the phone itself," not your computer.

## What's here
- `models.py` - the database tables (split, workout logs, weight logs, food presets, food logs, targets)
- `app.py` - the Flask app and every API route
- `requirements.txt` - the 3 Python packages this needs (Flask, Flask-SQLAlchemy, Flask-Cors)

## API endpoints, quick reference
| Method | Route                  | What it does                                    |
|--------|-------------------------|--------------------------------------------------|
| GET    | /api/split              | Get the full split (all days)                    |
| GET    | /api/split/<day>        | Get one day's exercise list                      |
| POST   | /api/split              | Replace a day's exercise list                     |
| POST   | /api/workouts           | Log a workout entry                               |
| GET    | /api/workouts           | List workouts (optional ?day= or ?exercise=)      |
| GET    | /api/workouts/last      | Most recent entry for ?exercise= (for suggestions)|
| POST   | /api/weight             | Log/overwrite today's weight                      |
| GET    | /api/weight             | List all weight entries                           |
| GET    | /api/weight/average     | 7-day rolling average                             |
| GET    | /api/foods/presets      | List preset foods                                 |
| POST   | /api/foods/presets      | Add a preset food                                 |
| POST   | /api/foods              | Log a food entry                                  |
| GET    | /api/foods              | List food entries (optional ?date=)               |
| GET    | /api/targets            | Get calorie/protein targets                       |
| POST   | /api/targets            | Set calorie/protein targets                       |
| GET    | /api/home               | Everything the Home tab needs in one call         |

Every endpoint that takes a body expects JSON, e.g.:
```
curl -X POST http://127.0.0.1:5000/api/weight \
  -H "Content-Type: application/json" \
  -d '{"date": "2026-08-17", "weight": 45.3}'
```
