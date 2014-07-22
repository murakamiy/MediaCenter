CREATE TABLE programme (
    transport_stream_id INTEGER,
    service_id INTEGER,
    event_id INTEGER,
    series_id INTEGER DEFAULT -1,
    title TEXT,
    smb_filename TEXT DEFAULT '',
    channel TEXT,
    category TEXT,
    start INTEGER,
    stop INTEGER,
    foundby TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now')),
    PRIMARY KEY (transport_stream_id, service_id, event_id)
);

CREATE INDEX idx_programme_series_id ON programme (series_id);
CREATE INDEX idx_programme_title ON programme (title);
CREATE INDEX idx_programme_smb_filename ON programme (smb_filename);
CREATE INDEX idx_programme_channel ON programme (channel);
CREATE INDEX idx_programme_category ON programme (category);
CREATE INDEX idx_programme_start ON programme (start);


CREATE TABLE play (
    transport_stream_id INTEGER,
    service_id INTEGER,
    event_id INTEGER,
    play_time INTEGER DEFAULT 0,
    aggregate INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE INDEX idx_play_id ON play (transport_stream_id, service_id, event_id);
CREATE INDEX idx_play_aggregate ON play (aggregate);


CREATE TABLE series (
    series_id INTEGER PRIMARY KEY,
    title TEXT,
    rating INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE UNIQUE INDEX idx_series_title ON series (title);
