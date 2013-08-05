class Git_Ruby
  require 'octokit'

  def initialize
    @xpodir   = "/tmp/tmpxpo"
    @username = 'RobvanB'
    @password = 'noneofyourbeeswax'
    @cred     = { :login => @username, :password => @password }
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
    #@client = Octokit::Client.new(:login => usernam, :password => password )
    @client = Octokit::Client.new(@cred)
    # TODO: use Oauth

    user_repo = { :username => @cred[:login], :repo => repo_name }

    # Check if we have a repo - if not, create it
    #if (!@client.repository?({:username => username, :repo => repo_name }))
    if (!@client.repository?(user_repo))
      puts "No Repo #{repo_name}, creating new repo"
      @client.create_repository(repo_name)
      @repo = @client.repository(user_repo)
    else
      puts "repo #{repo_name} exists."
      @repo = @client.repository(user_repo)
    end

    # We now have a repo - Now we need to create / update the local git, and then push the code
    if @repo

    end


    sleep 2 #leave some time between the GIT API requests
    #self.delete_repo({:username => username, :repo => reponame })
  end

  def delete_repo(repo)
    if (@@client.delete_repository(repo))
      puts "#{repo} deleted."
    end
  end

end