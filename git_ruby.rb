class Git_Ruby
  require 'octokit'
  require 'nokogiri'
  require 'fileutils'

  def initialize
    # Open the config file with the account info
    cfg = File.open("gitruby.xml")
    doc = Nokogiri::XML(cfg)
    cfg.close

    # Assign values from configfile
    doc.xpath("//account").each { |acc|
      #puts acc.to_s
      @username  = acc.xpath("un")[0].content
      @password  = acc.xpath("pw")[0].content
      @xpodir    = acc.xpath("xpodir")[0].content
      @main_repo = acc.xpath("main_repo")[0].content #Single repo, subdir per customer
      @arch_dir  = acc.xpath("arch_dir")[0].content
    }

    @cred      = { :login => @username, :password => @password }
  end

  def run
    # Pull the emails with the XPO attachments, extract the attachments and move them to our input folder
    if !system('./getEmailAttach.sh')
      puts "Problem pulling in email"
     exit
    end
    Dir.chdir(@xpodir)
    if Dir.pwd == @xpodir
      xpolist = Dir.glob("*.xpo")
    end

    xpolist.each{|f| self.find_or_create_repo(f)}
  end

  def parseFilename(filename)
    filename   = filename.gsub('.xpo', "") #Remove .xpo
    commit_msg = ""

    #Grab the customer name from the commit msg (2nd line - for now, XML later ?)
    line_counter = 1
    file = File.new(filename + ".commit", "r")
    while (line = file.gets)
      if line_counter == 2
        customer = line.chomp  #Chomp removes new line character
      elsif line_counter > 2 && line.length > 0
        commit_msg = commit_msg + line
      end
      line_counter = line_counter + 1
    end
    file.close
    return [customer, commit_msg]
  end

  def find_or_create_repo(xpo_filename)
    ret_array = self.parseFilename(xpo_filename)
    customer = ret_array[0]
    commit_msg = ret_array[1]
    @client = Octokit::Client.new(@cred)
    # TODO: use Oauth

    xpo_filename_plus_path = @xpodir + "/" + xpo_filename
    user_repo = { :username => @cred[:login], :repo => @main_repo}

    begin
      # Check if we have a repo - if not, create it
      if !@client.repository?(user_repo)
        puts "No Repo #{@main_repo}, creating new repo"
        @client.create_repository(@main_repo , :auto_init => true)
        @repo_exists = true
        sleep 3
      else
        puts "repo #{@main_repo} exists."
        @repo_exists = true
      end
    rescue => ex
      puts "Problem connecting to GitHub: #{ex.message}"
      return
    end

    @repo = @client.repository(user_repo)

    sleep 2 #leave some time between the GIT API requests    (not sure if required)

    self.add_content(user_repo, xpo_filename, xpo_filename_plus_path, customer, commit_msg)
  end

  def add_content(user_repo, xpo_filename, xpo_filename_plus_path, customer, commit_msg)
    puts "Customer : #{customer}"

    # Use the API to add the new file and commit to the GitHb DB. This way we don't need a local git
    # See: http://developer.github.com/v3/git/

    #Add the content to the repo
    if @repo_exists
      # See if the current file is in the repo
      # See here: http://stackoverflow.com/questions/15919635/on-github-api-what-is-the-best-way-to-get-the-last-commit-message-associated-w

      # 1. First get a list of files
      # 1a: Get reference object of the branch (master)
      refs = @client.refs(user_repo, "heads/master")

      if refs
        ref_object_sha = refs.object.sha
        # 1b: Get the commit object
        commit_obj = @client.commits(user_repo, ref_object_sha)

        # 1c Get the tree sha from the commit object to get to the tree object
        # The first one in the array should be our last commit
        tree_sha = commit_obj[0].commit.tree.sha

        # See if we have a node for the customer
        tree_obj = @client.tree(user_repo, tree_sha)
        cur_file = customer + "/" + xpo_filename
        @have_cust = false
        tree_obj.tree.each{|t|
          puts "File: #{t.path}"
          if t.path == customer
            @have_cust = true
            @customer_node_sha = t.sha
            puts "Customer #{customer} found"
            break
          end
        } #tree_ob.each loop

        if @have_cust
          puts "Check if we have the file for #{customer}"
          tree_obj = @client.tree(user_repo, @customer_node_sha)
          @have_file = false
          tree_obj.tree.each{|t|
            if t.path == xpo_filename
              @update_file_sha = t.sha
              puts "File found for #{customer} : #{t.path}"
              @have_file = true
              break
            end
          }
        end
      end

      if @have_file == true
        puts "updating...."
        content_and_commit = @client.update_contents(user_repo, cur_file, commit_msg, @update_file_sha, :file => xpo_filename_plus_path)
      else
        puts "#{cur_file} not found in repo #{@main_repo}, adding..."
        content_and_commit = @client.create_contents(user_repo, cur_file, commit_msg,  :file => xpo_filename_plus_path)
      end
      # Move files
      fromfile   = @xpodir + "/" + xpo_filename
      tofile     = @arch_dir + "/" + xpo_filename
      puts "#{fromfile} to #{tofile}"
      FileUtils.mv(fromfile, tofile)
      filename   = xpo_filename.gsub('.xpo', "") #Remove .xpo
      fromfile   = @xpodir + "/" + filename + ".commit"
      tofile     = @arch_dir + "/" + filename + ".commit"
      puts "#{fromfile} to #{tofile}"
      FileUtils.mv(fromfile, tofile)
    else
      #No Repo
      puts "No Repo, exiting."
      exit
    end
  end
end