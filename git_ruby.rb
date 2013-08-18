class Git_Ruby
  require 'octokit'

  def initialize
    @xpodir    = '/xpotmp'
    @username  = 'RobvanB'
    @password  =  ''
    @local_git = '/tmp/gittmp'
    @cred      = { :login => @username, :password => @password }
  end

  def listFiles
    Dir.chdir(@xpodir)
    if Dir.pwd == @xpodir
      xpolist = Dir.glob("*.xpo")
    end

    xpolist.each{|f| self.find_or_create_repo(f)}
  end

  def parseFilename(filename)
    filename.gsub('SharedProject_', "").gsub('.xpo', "")
  end

  def find_or_create_repo(xpo_filename)
    repo_name = self.parseFilename(xpo_filename)
    @client = Octokit::Client.new(@cred)
    # TODO: use Oauth

    xpo_filename_plus_path = @xpodir + "/" + xpo_filename
    user_repo = { :username => @cred[:login], :repo => repo_name}

    begin
      # Check if we have a repo - if not, create it
      if !@client.repository?(user_repo)
        puts "No Repo #{repo_name}, creating new repo"
        @client.create_repository(repo_name , :auto_init => true)
        @repo_exists = false
        sleep 3
      else
        puts "repo #{repo_name} exists."
        @repo_exists = true
      end
    rescue
      puts "Problem connecting to GitHub"
      return
    end

    @repo = @client.repository(user_repo)

    sleep 1 #leave some time between the GIT API requests    (not sure if required)

    # Use the API to add the new file and commit to the GitHb DB. This way we don't need a local git
    # See: http://developer.github.com/v3/git/

    #Add the content to the repo
    if @repo_exists
      # See if the current file is in the repo - Assumption is that there are no subfolders
      # See here: http://stackoverflow.com/questions/15919635/on-github-api-what-is-the-best-way-to-get-the-last-commit-message-associated-w

      # 1. First get a list of files
      # 1a: Get reference object of the branch (master)
      refs = @client.refs(user_repo, "heads/master")

      if refs
        ref_object_sha = refs.object.sha

        # 1b: Get the commit object
        #puts "object sha: #{ref_object_sha}"
        commit_obj = @client.commits(user_repo, ref_object_sha)

        # 1c Get the tree sha from the commit object to get to the tree object
        #puts "commits: #{commit_obj.class}"
        #commit_obj.each{|c| puts "C: #{c.commit.tree}"}

        # The first one in the array should be our last commit
        tree_sha = commit_obj[0].commit.tree.sha
        #puts "tree_sha: #{tree_sha}"

        # Make sure we have the file
        # TODO: at this point we assume that we only have 1 xpo in the repo - this need to be reviewed/expanded
        tree_obj = @client.tree(user_repo, tree_sha)
        puts tree_obj.inspect
        tree_obj.tree.each{|t|
          if t.path == xpo_filename
            @file_in_repo = true
            #puts t.sha
            @update_file_sha = t.sha
            puts "file found"
          else
            @file_in_repo = false
            puts "#{xpo_filename} not found in repo #{repo_name}"
          end
        }

        if @file_in_repo == true
          puts "updating...."
          content_and_commit = @client.update_contents(user_repo, xpo_filename, "Updating content 2", @update_file_sha, :file => xpo_filename_plus_path)
        end
      end
    else
      # Add new file
      content_and_commit = @client.create_contents(user_repo, xpo_filename, "Adding content 2", :file => xpo_filename_plus_path)
    end
    puts content_and_commit

    sleep 2 #leave some time between the GIT API requests

    #Testing
    #self.delete_repo({:username => username, :repo => reponame })
end

  def delete_repo(repo)
    if (@@client.delete_repository(repo))
      puts "#{repo} deleted."
    end
  end

end