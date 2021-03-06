--Blocked SQL:
;WITH BlockSession
         AS (SELECT 
                    DBname = db_name (a.dbid),
                    spid,
                    blocked,
                    waitSecond = waittime / 1000,
                    a.status,
                    sqlMessage = Replace (substring (b.text, 1, 340), '''', ''''),
                    lastWaitType = a.lastwaittype,
                    CommandType = a.cmd,
                    loginame,
                    killSpid= 'kill '+cast(spid as varchar(MAX)) +';',
                    hostName = replace (hostname, ' ', ''),
                    programName = '''' + replace (program_name, ' ', '') + '''',
                    a.cpu,/*进程累积的CPU时间*/
                    --CPUTime = er.cpu_time ,
                    IOReads = er.logical_reads + er.reads,
                    IOWrites = er.writes,
                    StartTime = er.start_time,
                    Protocol = con.net_transport,
                    ConnectionWrites = con.num_writes,
                    ConnectionReads = con.num_reads,
                    Authentication = con.auth_scheme,  /*身份验证方案*/
                    ClientAddress = con.client_net_address,
                    a.sql_handle
               FROM sys.sysprocesses AS a WITH (NOLOCK)
                    CROSS APPLY sys.dm_exec_sql_text (sql_handle) AS b
                    LEFT JOIN sys.dm_exec_requests er
                       ON er.session_id = spid
                    LEFT JOIN sys.dm_exec_connections con
                       ON con.session_id = spid),
      BlockedSess /*blocked session*/
         AS (SELECT *
               FROM BlockSession
              WHERE     blocked > 0
                    AND sql_handle <>
                           0x0000000000000000000000000000000000000000
                    AND waitSecond > 2)
 
 SELECT *
   FROM BlockSession AS A
  WHERE     EXISTS
               (SELECT blocked
                  FROM BlockedSess B
                 WHERE b.blocked = a.spid)
        AND NOT EXISTS
               (SELECT spid
                  FROM BlockedSess B
                 WHERE B.spid = a.spid)
 UNION ALL
 SELECT * FROM BlockedSess
