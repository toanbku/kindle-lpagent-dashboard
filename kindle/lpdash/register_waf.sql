-- Register the "LP Agent" WAF app in /var/local/appreg.db
-- (open it with: lipc-set-prop com.lab126.appmgrd start app://com.lpagent.dashboard)
-- Undo: sqlite3 /var/local/appreg.db < unregister_waf.sql
BEGIN;
INSERT OR IGNORE INTO handlerIds (handlerId) VALUES ('com.lpagent.dashboard');
INSERT OR REPLACE INTO properties (handlerId, name, value) VALUES ('com.lpagent.dashboard', 'command', '/usr/bin/mesquite -l com.lpagent.dashboard -c file:///mnt/us/apps/xyz.lpagent.dashboard/');
INSERT OR REPLACE INTO properties (handlerId, name, value) VALUES ('com.lpagent.dashboard', 'unloadPolicy', 'unloadOnPause');
INSERT OR REPLACE INTO properties (handlerId, name, value) VALUES ('com.lpagent.dashboard', 'framework', '');
INSERT OR REPLACE INTO associations (handlerId, interface, contentId, defaultAssoc) VALUES ('com.lpagent.dashboard', 'application', 'none', 'false');
COMMIT;
