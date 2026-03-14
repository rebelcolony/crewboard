-- Create additional databases for Solid Cache, Queue, and Cable.
-- The primary database (crewboard_production) is created automatically
-- by the POSTGRES_DB env var on the PostgreSQL container.

CREATE DATABASE crewboard_production_cache;
CREATE DATABASE crewboard_production_queue;
CREATE DATABASE crewboard_production_cable;
