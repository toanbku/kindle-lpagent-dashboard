-- Remove the "LP Agent" WAF app from /var/local/appreg.db
BEGIN;
DELETE FROM associations WHERE handlerId='com.lpagent.dashboard';
DELETE FROM properties WHERE handlerId='com.lpagent.dashboard';
DELETE FROM handlerIds WHERE handlerId='com.lpagent.dashboard';
COMMIT;
