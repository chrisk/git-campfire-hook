Git Campfire Hook
=================

Making a better git post-receive Campfire hook. Most of them seem like they were
hacked over from old svn hooks--ours certainly is--and they don't handle edge
cases and branches well.

Installation
============

Initiated from the post-recieve hook.

Example `repository/.git/hooks/post-receive`-script, with hook.rb and 
notification.rb placed in the hooks-directory, make sure the post-receive
file is executable.

    while read old_rev new_rev ref; do
            ruby hooks/hook.rb $ref $old_rev $new_rev
    done
