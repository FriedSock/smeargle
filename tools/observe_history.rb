#require File.join(File.dirname(__FILE__), 'plugin/diff_gatherer.rb')
#require 'ruby-debug'
#
TEMP_FILENAME = "temp1"
TEMP_FILENAME_PATH = File.join(File.dirname(__FILE__), TEMP_FILENAME)
TEMP_FILENAME2 = "temp2"
TEMP_FILENAME_PATH2 = File.join(File.dirname(__FILE__), TEMP_FILENAME2)

if __FILE__ == $0
  search_term, gunk = ARGV
  `cd #{File.dirname(__FILE__)}; ./search_history.sh '#{search_term}' > #{TEMP_FILENAME}`

  raw = File.open(TEMP_FILENAME_PATH).read
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

    `git show #{commit} | bundle exec ruby changed_lines.rb > #{TEMP_FILENAME}`
    #TODO: Checkout, might need to do some stashing and popping

    raw = File.open(TEMP_FILENAME_PATH).read
    file_changes = raw.split(/^$/)
    file_changes.each do |change|
      filename = change.match(/filename: (\S*)$/)[1]
      File.open(TEMP_FILENAME_PATH2, 'w') { |f| f.write(change) }
      PAT = File.join('tools', TEMP_FILENAME2)
      `cd $(git rev-parse --show-toplevel); vim -O #{filename} #{PAT} < \`tty\` > \`tty\` `
    end
  end

  #Clean up
  `rm #{TEMP_FILENAME_PATH}`
end


