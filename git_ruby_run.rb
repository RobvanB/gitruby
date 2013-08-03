class Git_Ruby_Run

  require './git_ruby.rb'

  def self.run
    gr = Git_Ruby.new

    gr.connect
  end

  run
end