-----
-- User configuration file for lsyncd.
-- 
-- This example uses refers to a problem in unix. 
-- 
-- You have a shared directory for a set of users and you want
-- to ensure all users have read and write permissions on all
-- files in there. Unfortunally sometimes users mess with their 
-- umask, and create files in there that are not read/write/deleteable
-- by others. Usually this involves frequent handfixes by a sysadmin,
-- or a cron job that recursively chmods/chowns the whole directory.
--
-- This is another approach to use lsyncd to continously fix permissions.
-- 
-- One second after a file is created/modified it checks for its permissions 
-- and forces group permissions on it.
--
-- This is example regards more the handcraft of bash scripting than lsyncd.
-- An alternative to this would be to load a Lua-Posix library and do the 
-- permission changes right within the onAction handlers.

-- forces this group
fgroup = "axel"

command = 
-- checks if the group is the one enforced and sets them if not 
[[
perm=`stat -c %A ^sourcePathname`
if [ `stat -c %G ^sourcePathname` != ]]..fgroup..[[ ]; then
	/bin/chgrp ]]..fgroup..[[ ^sourcePathname || /bin/true; 
fi 
]] ..

-- checks if the group permissions are rw and sets them 
[[
if [ `expr match $perm "....rw"` == 0 ]; then 
	/bin/chmod g+rw ^sourcePathname || /bin/true; 
fi 
]] ..

-- and forces the executable bit for directories.
[[
if [ -d ^sourcePathname ]; then
	if [ `expr match $perm "......x"` == 0 ]; then 
		/bin/chmod g+x ^^sourcePathname || /bin/true;
	fi 
fi 
]]

-- on startup recursevily sets all group ownerships
-- all group permission to rw for all
-- and to executable for directories
--
-- the hash in the first line is important, otherwise due to the starting
-- slash, syncd will think its a call to the binary /bin/chgrp only
-- instead of a bash script.
-- 
startup = 
[[#
/bin/chgrp -R ]]..fgroup..[[ ^source || /bin/true &&
/bin/chmod -R g+rw ^source || /bin/true &&
/usr/bin/find ^source -type d | xargs chmod g+x 
]]


-----
-- for testing purposes. uses bash command to hold local dirs in sync.
--
gforce = {
	maxProcesses = 99,
	delay = 1,
	onStartup = startup,
	onAttrib = command,
	onCreate = command,
	onModify = command,
	-- does nothing on moves, they won change permissions.
	onMove   = true,
}

sync{gforce, source="/path/to/share"}

