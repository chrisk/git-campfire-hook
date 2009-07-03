require 'rubygems'
require 'tinder'

class GitCampfireNotification

  def initialize(options = {})
    # campfire_config keys: subdomain, use_ssl, email, password, room
    @campfire_config = options[:campfire_config]

    # git keys: ref_name, old_revision, new_revision
    @ref_name     = options[:ref_name]
    @old_revision = options[:old_revision]
    @new_revision = options[:new_revision]

    @old_revision_type = `git cat-file -t #{@old_revision} 2> /dev/null`.strip
    @new_revision_type = `git cat-file -t #{@new_revision} 2> /dev/null`.strip

    if ref_name_type.include?("branch")
      send "#{change_type}_branch"
    elsif ref_name_type.include?("tag")
      send "#{change_type}_tag"
    end
  end


  private

  def campfire_room
    if @campfire.nil?
      @campfire = Tinder::Campfire.new(@campfire_config[:subdomain], :ssl => @campfire_config[:use_ssl])
      @campfire.login(@campfire_config[:email], @campfire_config[:password])
    end
    @campfire_room ||= @campfire.find_room_by_name(@campfire_config[:room])
  end

  def project_name
    project_name = `git rev-parse --git-dir 2>/dev/null`.strip
    if project_name == ".git"
      project_name = File.basename(Dir.pwd)
    end
    project_name.sub(/\.git$/, "")
  end

  def change_type
    if @old_revision =~ /^0*$/
      :create
    elsif @new_revision =~ /^0*$/
      :delete
    else
      :update
    end
  end

  def short_ref_name
    @ref_name.match(%r{^refs/(?:tags|heads|remotes)/(.+)$})[1]
  end

  def ref_name_type
    rev_type = (change_type == :delete) ? @old_revision_type : @new_revision_type
    ref_name_types = {%w(tags    commit) => "tag",
                      %w(tags    tag)    => "annotated tag",
                      %w(heads   commit) => "branch",
                      %w(remotes commit) => "tracking branch"}
    @ref_name.match(%r{^refs/(tags|heads|remotes)/.+$})
    ref_name_types[[$1, rev_type]]
  end


  def new_commits
    revision_range = (change_type == :create) ? @new_revision : "#{@old_revision}..#{@new_revision}"

    other_branches = `git for-each-ref --format='%(refname)' refs/heads/ | grep -F -v #{@ref_name}`
    sentinel = "=-=-*-*-" * 10
    raw_commits = `git rev-parse --not #{other_branches} | git rev-list --reverse --pretty=format:'%cn%n%s%n%n%b#{sentinel}' --stdin #{revision_range}`.split(sentinel)
    raw_commits.pop # last is empty because there's an ending sentinel

    raw_commits.inject([]) { |commits, raw_commit|
      lines = raw_commit.strip.split("\n")
      commits << {:revision  => lines[0].sub(/^commit /, ""),
                  :committer => lines[1],
                  :message   => lines[2..-1].join("\n")}
    }
  end

  def speak_new_commits
    new_commits.each do |c|
      campfire_room.speak "#{c[:committer]} just committed #{c[:revision]}"
      campfire_room.paste "[#{project_name}] #{c[:message]}"
    end
  end


  def update_branch
    if `git rev-list #{@new_revision}..#{@old_revision}`.empty?
      update_type = :fast_foward
    elsif newrev == `git merge-base #{@old_revision} #{@new_revision}`
      update_type = :rewind
      campfire_room.speak "Notice: the remote #{ref_name_type} #{project_name}/#{short_ref_name} was just rewound to a previous commit"
    else
      update_type = :force
      campfire_room.speak "Notice: the remote #{ref_name_type} #{project_name}/#{short_ref_name} was just force-updated"
    end

    unless update_type == :rewind
      speak_new_commits
    end
  end

  def create_branch
    campfire_room.speak "A new remote #{ref_name_type} was just pushed to #{project_name}/#{short_ref_name}:"
    speak_new_commits
  end

  def delete_branch
    campfire_room.speak "The remote #{ref_name_type} #{project_name}/#{short_ref_name} was just deleted"
  end

  def delete_tag
    campfire_room.speak "The #{ref_name_type} #{project_name}/#{short_ref_name} was just deleted"
  end
end
