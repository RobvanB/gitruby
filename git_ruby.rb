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
        puts "got refs"
        ref_object_sha = refs.object.sha
        #puts "1 #{refs.inspect}"
        #puts "2 #{refs.methods(true)}"
        #puts "3 #{refs.rels.methods}"
        #puts "4 #{refs.ref}"
        #puts "5 #{refs.ref.class}"
        #puts "6 #{refs.rels.class}"
        #puts "7 #{refs.rels.keys.methods}"
        #puts refs.process_value ":type"
        #puts refs.object.type
        #puts refs.object.sha
        #puts refs.object.methods(true)

        # 1b: Get the commit object
        commit_obj = @client.commit(user_repo, ref_object_sha)
        #puts commit_obj.files
        commit_obj.files.each{|f|
          if f.filename == xpo_filename
            @file_in_repo = true
            @update_file_sha = f.sha
          else
            @file_in_repo = false
            puts "#{xpo_filename} not found in repo #{repo_name}"
          end
          }
        if @file_in_repo
          content_and_commit = @client.update_contents(user_repo, xpo_filename, "Updating content 1", @update_file_sha, :file => xpo_filename_plus_path)
        end
      end
    else
      content_and_commit = @client.create_contents(user_repo, xpo_filename, "Adding content 1", :file => xpo_filename_plus_path)
    end


    # Get all the commits and select the last one so we can get the tree
    #commits = @client.commits(@repo)

    #commits.each{|c| puts c.name}
    sleep 2 #leave some time between the GIT API requests

    #Testing
    #self.delete_repo({:username => username, :repo => reponame })
end
=begin
    # We now have a repo - Now we need to create / update the local git, and then push the code

    if @repo
      Dir.chdir(@local_git)
      if !Dir.chdir(@repo.name)
        Dir.mkdir(@repo.name)
        Dir.chdir(@repo.name)
      end
    end
=end



  def delete_repo(repo)
    if (@@client.delete_repository(repo))
      puts "#{repo} deleted."
    end
  end

end