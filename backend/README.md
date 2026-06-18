# CivicPulse Backend

FastAPI service powering infrastructure reporting, healthcare queuing, and GBV safety features.

## Quick Start

### 1. Supabase Setup

1. Create a free project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** and run the full contents of [`sql/schema.sql`](sql/schema.sql).
3. Copy your project URL and `anon` key from **Project Settings → API**.

### 2. Local Environment

```bash
# Inside the backend/ directory
cp .env.example .env
# Edit .env and paste your SUPABASE_URL and SUPABASE_KEY
```

### 3. Create & Activate Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate          # Linux / macOS
# .venv\Scripts\activate           # Windows
```

### 4. Install Dependencies

```bash
pip install -r requirements.txt
```

### 5. Run the Development Server

```bash
uvicorn app.main:app --reload --port 8000
```

Open **http://localhost:8000/docs** to explore the interactive Swagger UI.

---

## API Endpoints

### Infrastructure Reports `/api/reports`

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/reports/` | Submit a new pothole, traffic light, or animal report |
| `GET` | `/api/reports/` | List reports (filter by `type` and/or `status`) |
| `GET` | `/api/reports/nearby` | Find reports within a radius (km) of lat/lon |
| `PATCH` | `/api/reports/{id}` | Update a report's status |

### Healthcare Queue `/api/queues`

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/queues/` | Register a new patient; assigns queue position |
| `GET` | `/api/queues/` | Retrieve full queue sorted by triage priority |
| `GET` | `/api/queues/{id}` | Fetch a single patient entry |
| `PUT` | `/api/queues/{id}` | Update patient state — **triggers Supabase Realtime** |
| `DELETE` | `/api/queues/{id}` | Remove a discharged patient |

---

## Supabase Realtime (Flutter Integration)

When the `PUT /api/queues/{id}` endpoint updates a row, Supabase broadcasts a
`postgres_changes` event on the `queues` table. Subscribe in Flutter like this:

```dart
supabase
  .channel('public:queues')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'queues',
    callback: (payload) {
      // Rebuild queue board UI with payload.newRecord
    },
  )
  .subscribe();
```

> **Note:** Realtime must be enabled for the `queues` table.
> The `schema.sql` file includes `ALTER PUBLICATION supabase_realtime ADD TABLE queues;`
> — make sure this line was executed in the Supabase SQL Editor.

---

## Deployment (Render / Koyeb)

Set the following environment variables in your hosting dashboard:

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_KEY` | Your Supabase anon key |

**Start command:**
```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```
