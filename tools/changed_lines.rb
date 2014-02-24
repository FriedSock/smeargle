require File.join(File.dirname(__FILE__), '../plugin/diff_gatherer.rb')
require 'ruby-debug'

if __FILE__ == $0
  raw = ARGF.read
  matches = raw.scan /^diff --git a\/((?:[a-zA-Z0-9_-]\/?)+\.[a-z]+) (?:[a-zA-Z0-9_-]\/?)+\.[a-z]+$/
  raw = raw.split(/^diff --git a/)[1..-1]

  raw.each.with_index do |blob, i|
    puts ''
    puts "filename: #{matches[i]}"
    puts DiffGatherer.new(nil,nil).gather_git_diff(blob)[:additions].map { |l| l[:original_line] }
  end
end
