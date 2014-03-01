require 'ruby-debug'

EXECUTION_DIR = `pwd`.chomp
Dir.chdir(`git rev-parse --show-toplevel`.chomp)

def quit commit
  `git checkout #{commit}`
  `git stash pop`

  #refresh the file system incase the execution directory did not exist in one
  #of the commits that was checkout out
  `cd #{EXECUTION_DIR}`
  exit
end

def clean_up
  `rm #{TEMP_FILENAME}`
  `rm #{TEMP_FILENAME2}`
end

TEMP_FILENAME = "/tmp/temp1"
TEMP_FILENAME2 = "/tmp/temp2"

if __FILE__ == $0
  #Preserve the current state before we go exploring
  `git stash -u`
  orig_commit = `git rev-parse HEAD`.chomp

  search_term, gunk = ARGV
  `cd #{File.join(EXECUTION_DIR, File.dirname(__FILE__))}; ./search_history.sh '#{search_term}' > #{TEMP_FILENAME}`

  raw = File.open(TEMP_FILENAME).read
  commits = raw.split(/^$/)

  commits.each do |c|
    commit = c.match(/revision: (\S*)$/)[1]
    parent = c.match(/parent: (\S*)$/)[1]
    commit_message = c.match(/commit_message: (.*)/)[1]

    puts "commit where changes occured: #{commit}"
    puts "message: #{commit_message}"

    puts "press c to continue, n for next, q to quit"
    response = $stdin.gets.chomp
    next if response == 'n'
    quit(orig_commit) if response == 'q'


    `git show #{commit} > #{TEMP_FILENAME}`
    #TODO: Checkout, might need to do some stashing and popping

    `git checkout #{parent}`

    raw = File.open(TEMP_FILENAME).read
    filenames = raw.scan(/^diff --git a\/([\w\-.\/ ]+) b\/(?:[\w\-.\/ ]+)+$/)
    file_changes = raw.split(/^diff --git a\/(?:[\w\-.\/ ]+) b\/(?:[\w\-.\/ ]+)+$/)[1..-1].zip filenames
    file_changes.each do |change, filename|
      File.open(TEMP_FILENAME2, 'w') { |f| f.write(change) }
      `vim -O #{filename} #{TEMP_FILENAME2} < \`tty\` > \`tty\` `
    end
    clean_up
  end
  quit orig_commit
end

