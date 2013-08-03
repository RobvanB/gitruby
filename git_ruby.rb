class Git_Ruby
  require 'octokit'

  def connect
    username = 'RobvanB'
    reponame = "RobvanB-gitrubytmp"

    @@client = Octokit::Client.new(:login => username, :password => 'noneofyourbusiness')
    # TODO: use Oauth

    if (!@@client.repository?({:username => username, :repo => reponame }))
      puts "No Repo #{reponame}, creating new repo"
      @@client.create_repository(reponame)
    else
      puts "repo #{reponame} exists."
      @@repo = @@client.repository({:username => username, :repo => reponame })
    end

    #self.delete_repo({:username => username, :repo => reponame })
  end

  def delete_repo(repo)
    if (@@client.delete_repository(repo))
      puts "#{repo} deleted."
    end
  end

end