require 'ruby-debug'

TEMP_FILENAME = "/tmp/temp1"
TEMP_FILENAME2 = "/tmp/temp2"

if __FILE__ == $0
  search_term, gunk = ARGV
  `cd #{File.dirname(__FILE__)}; ./search_history.sh '#{search_term}' > #{TEMP_FILENAME}`

  raw = File.open(TEMP_FILENAME).read
  commits = raw.split(/^$/)

  commits.each do |c|
    commit = c.match(/revision: (\S*)$/)[1]
    parent = c.match(/parent: (\S*)$/)[1]
    commit_message = c.match(/commit_message: (.*)/)[1]

    puts "commit where changes occured: #{commit}"
    puts "message: #{commit_message}"

    puts "press y to continue or n to exit"
    response = $stdin.gets.chomp
    exit if response == 'n'

    `git show #{commit} > #{TEMP_FILENAME}`
    #TODO: Checkout, might need to do some stashing and popping

    raw = File.open(TEMP_FILENAME).read
    filenames = raw.scan(/^diff --git a\/([\w\-.\/ ]+) b\/(?:[\w\-.\/ ]+)+$/)
    file_changes = raw.split(/^diff --git a\/(?:[\w\-.\/ ]+) b\/(?:[\w\-.\/ ]+)+$/)[1..-1].zip filenames
    file_changes.each do |change, filename|
      File.open(TEMP_FILENAME2, 'w') { |f| f.write(change) }
      `cd $(git rev-parse --show-toplevel); vim -O #{filename} #{TEMP_FILENAME2} < \`tty\` > \`tty\` `
    end
  end

  #Clean up
  `rm #{TEMP_FILENAME_PATH}`
end


