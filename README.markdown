Git Campfire Hook
=================

Making a better git post-receive Campfire hook. Most of them seem like they were
hacked over from old svn hooks--ours certainly is--and they don't handle edge
cases and branches well.


Installation
============

To install, run `hook.rb` from your repository's post-receive hook. The hook
should contain something like this:

    while read old_rev new_rev ref; do
      ruby hooks/hook.rb $ref $old_rev $new_rev
    done

Make sure the `post-receive` script is executable (otherwise it'll be ignored by
git).

TODO: Add notes on configuring the git repository with Campfire settings.
