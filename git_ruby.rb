class Git_Ruby
  require 'octokit'

  def initialize
    @xpodir    = '/xpotmp'
    @username  = 'RobvanB'
    @password  =  'DRiZdIIDr23G'
    @cred      = { :login => @username, :password => @password }
    @main_repo = "AKARepo" #Single repo, subdir per customer
  end

  def listFiles
    # Pull the emails with the XPO attachments, extract the attachments and move them to our input folder
    #if !system('./getEmailAttach.sh')
    #  puts "Problem pulling in email"
    # exit
    #end
    #TODO: Re-enable
    Dir.chdir(@xpodir)
    if Dir.pwd == @xpodir
      xpolist = Dir.glob("*.xpo")
    end

    xpolist.each{|f| self.find_or_create_repo(f)}
  end

  def parseFilename(filename)
    filename = filename.gsub('.xpo', "") #Remove .xpo

    #Grab the customer name from the commit msg (2nd line - for now, XML later ?)
    line_counter = 1
    file = File.new(filename + ".commit", "r")
    while (line = file.gets)
      if line_counter == 2
        @customer = line.chomp  #Chomp removes new line character
      end
      line_counter = line_counter + 1
    end
    file.close
  end

  def find_or_create_repo(xpo_filename)
    #repo_name = self.parseFilename(xpo_filename)
    self.parseFilename(xpo_filename)
    @client = Octokit::Client.new(@cred)
    # TODO: use Oauth

    xpo_filename_plus_path = @xpodir + "/" + xpo_filename
    #user_repo = { :username => @cred[:login], :repo => repo_name}
    user_repo = { :username => @cred[:login], :repo => @main_repo}

    begin
      # Check if we have a repo - if not, create it
      if !@client.repository?(user_repo)
        #puts "No Repo #{repo_name}, creating new repo"
        puts "No Repo #{@main_repo}, creating new repo"
        #@client.create_repository(repo_name , :auto_init => true)
        @client.create_repository(@main_repo , :auto_init => true)
        @repo_exists = false
        sleep 3
      else
        #puts "repo #{repo_name} exists."
        puts "repo #{@main_repo} exists."
        @repo_exists = true
      end
    rescue => ex
      puts "Problem connecting to GitHub: #{ex.message}"
      return
    end

    @repo = @client.repository(user_repo)
    puts "Repo: #{@repo}"

    sleep 2 #leave some time between the GIT API requests    (not sure if required)

    puts "Customer : #{@customer}"

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
        cur_file = @customer + "/" + xpo_filename

        #puts tree_obj.inspect
        tree_obj.tree.each{|t|
          if t.path == cur_file
            @file_in_repo = true
            #puts t.sha
            @update_file_sha = t.sha
            puts "file found"
          else
            @file_in_repo = false
            puts "#{cur_file} not found in repo #{@main_repo}, adding..."
            #puts "INFO: #{user_repo} #{xpo_filename} #{xpo_filename_plus_path}"
            content_and_commit = @client.create_contents(user_repo, cur_file, "Adding content", xpo_filename_plus_path )
          end


          #if t.path == xpo_filename
          #  @file_in_repo = true
          #  #puts t.sha
          #  @update_file_sha = t.sha
          #  puts "file found"
          #else
          #  @file_in_repo = false
          #  puts "#{xpo_filename} not found in repo #{@main_repo}, adding..."
          #  puts "INFO: #{user_repo} #{xpo_filename} #{xpo_filename_plus_path}"
          #  content_and_commit = @client.create_contents(user_repo, xpo_filename, "Adding content", xpo_filename_plus_path )
          #end
        }

        ####
        exit
        ####

        if @file_in_repo == true
          puts "updating...."
          content_and_commit = @client.update_contents(user_repo, xpo_filename, "Updating content", @update_file_sha, xpo_filename_plus_path)
        end
      end
    else
      # Add new file( repo, path (in repo), message, content)
      puts "INFO: #{user_repo} #{xpo_filename} #{xpo_filename_plus_path}"
      content_and_commit = @client.create_contents(user_repo, xpo_filename, "Adding content", xpo_filename_plus_path)
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