-- CivicPulse PostgreSQL DB Schema

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    phone TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    id_number TEXT UNIQUE NOT NULL,
    alert_contacts JSONB NOT NULL DEFAULT '[]'::jsonb,
    role TEXT NOT NULL DEFAULT 'citizen' CHECK (role IN ('citizen', 'doctor', 'driver', 'volunteer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Existing development databases may already have users without id_number.
ALTER TABLE users ADD COLUMN IF NOT EXISTS id_number TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS alert_contacts JSONB NOT NULL DEFAULT '[]'::jsonb;
CREATE UNIQUE INDEX IF NOT EXISTS users_id_number_key ON users (id_number);

-- 2. INFRASTRUCTURE REPORTS TABLE
CREATE TABLE IF NOT EXISTS reports (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('pothole', 'traffic_light', 'animal')),
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved')),
    media_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. HEALTHCARE QUEUES TABLE
CREATE TABLE IF NOT EXISTS queues (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_name TEXT NOT NULL,
    patient_phone TEXT,
    symptoms TEXT,
    pain_level INTEGER CHECK (pain_level >= 1 AND pain_level <= 10),
    triage_status TEXT NOT NULL DEFAULT 'routine' CHECK (triage_status IN ('critical', 'urgent', 'routine')),
    queue_position INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'checked_in', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. WALK GROUPS TABLE
CREATE TABLE IF NOT EXISTS walk_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    route_name TEXT NOT NULL,
    start_latitude DOUBLE PRECISION NOT NULL,
    start_longitude DOUBLE PRECISION NOT NULL,
    end_latitude DOUBLE PRECISION NOT NULL,
    end_longitude DOUBLE PRECISION NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. ROW LEVEL SECURITY (RLS) & ACCESS POLICIES
-- For rapid hackathon development, we enable RLS but add permissive policies for testing.
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE walk_groups ENABLE ROW LEVEL SECURITY;

-- Users Policies
CREATE POLICY "Allow public read users" ON users FOR SELECT USING (true);
CREATE POLICY "Allow public insert users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update users" ON users FOR UPDATE USING (true);

-- Reports Policies
CREATE POLICY "Allow public read reports" ON reports FOR SELECT USING (true);
CREATE POLICY "Allow public insert reports" ON reports FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update reports" ON reports FOR UPDATE USING (true);

-- Queues Policies
CREATE POLICY "Allow public read queues" ON queues FOR SELECT USING (true);
CREATE POLICY "Allow public insert queues" ON queues FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update queues" ON queues FOR UPDATE USING (true);

-- Walk Groups Policies
CREATE POLICY "Allow public read walk_groups" ON walk_groups FOR SELECT USING (true);
CREATE POLICY "Allow public insert walk_groups" ON walk_groups FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update walk_groups" ON walk_groups FOR UPDATE USING (true);

-- 6. ENABLE SUPABASE REALTIME ON QUEUES TABLE
-- Supabase relies on the supabase_realtime publication to broadcast DB changes via WebSockets.
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE queues;
EXCEPTION
  WHEN duplicate_object THEN
    NULL; -- Table already added, safe to ignore
END;
$$;
