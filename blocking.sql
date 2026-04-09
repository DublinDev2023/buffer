🔍 1. Quick check: who is blocking whom

Run this:

SELECT 
    r.session_id,
    r.blocking_session_id,
    r.status,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    t.text AS query_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id <> 0;

👉 This shows:

Your blocked query (session_id)
The blocker (blocking_session_id)
🔗 2. See full blocking chain

This gives more context:

SELECT 
    s.session_id,
    r.blocking_session_id,
    r.status,
    r.wait_type,
    r.wait_time,
    t.text AS query_text
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id > 50;
🔒 3. Inspect locks directly
SELECT 
    tl.request_session_id,
    tl.resource_type,
    tl.resource_description,
    tl.request_mode,
    tl.request_status
FROM sys.dm_tran_locks tl
ORDER BY tl.request_session_id;

👉 Look for:

request_status = WAIT
Same resource held by another session
🧠 4. Identify the blocker query

Once you get the blocking session ID (say 57):

SELECT 
    r.session_id,
    r.status,
    r.command,
    t.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id = 57;
⚡ 5. Quick built-in tool (very useful)

Run:

EXEC sp_who2;
