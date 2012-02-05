CREATE TABLE play (
    service_id INTEGER,
    event_id INTEGER,
    series_id INTEGER DEFAULT -1,
    category_id INTEGER DEFAULT -1,
    channel TEXT,
    title TEXT,
    desc TEXT,
    category_1 TEXT,
    category_2 TEXT,
    start INTEGER,
    stop INTEGER,
    priority INTEGER,
    foundby TEXT,
    play_time_total INTEGER DEFAULT 0,
    play_time_queue INTEGER DEFAULT 0,
    length INTEGER,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now')),
    PRIMARY KEY (service_id, event_id)
);

CREATE INDEX idx_play_series_id ON play (series_id);
CREATE INDEX idx_play_category_id ON play (category_id);
CREATE INDEX idx_play_play_time_total ON play (play_time_total);
CREATE INDEX idx_play_play_time_queue ON play (play_time_queue);

/*

rating_series
    series_id
    title
    play_time
    play_count
    length
    created_at
    updated_at

rating_category
    category_id
    category_1
    category_2
    play_time
    play_count
    length
    created_at
    updated_at

CREATE TABLE error (
    id INTEGER PRIMARY KEY, 
    xml TEXT,
    type TEXT,
    value TEXT,
    message TEXT,
    created_at TEXT,
    updated_at TEXT
);


select strftime('%Y/%m/%d %H:%M:%S', '1328191356', 'unixepoch', 'localtime');
select datetime(1328405495, 'unixepoch', 'localtime');
SELECT strftime('%s','now');

*/
