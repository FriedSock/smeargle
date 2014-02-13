require 'generator'

class DiffGatherer

  def initialize file1, file2
    @file1 = file1
    @file2 = file2
  end

  def diff
   raw = `diff #{@file1} #{@file2}`
   out = ''
   harvest_type = nil
   line_range = nil
   change_border = nil

   {}.tap do |rethash|
     rethash[:additions] = []
     rethash[:deletions] = []
     rethash[:changes] = []

     raw.each_line do |line|
       if match = line.match(/^([0-9]*(?:,[0-9]*)?)(a|d|c)([0-9]*(?:,[0-9]*)?)$/)

         case match[2]
         when 'a'
           harvest_type = :add
           line_range = rangify match[3]
         when 'd'
           harvest_type = :delete
           line_range = rangify match[1]
         when 'c'
           harvest_type = :change
           line_range = rangify match[3]

           #For now, set deleted line content to nil, as its a pain to calculate
           #and not needed
           deletion_range = difference_rangify match[1], match[3]
           deletion_range.each do |l|
             rethash[:deletions] << { :line => l, :content => nil }
           end

         end
       else
         case harvest_type
         when :add
           if line_content = line.match(/^> (.*)$/)
             rethash[:additions] << { :line => line_range.next, :content => line_content[1] }
           end
         when :delete
           if line_content = line.match(/^< (.*)$/)
             rethash[:deletions] << { :line => line_range.next, :content => line_content[1] }
           end
         when :change
           if line_content = line.match(/^> (.*)$/)
             rethash[:changes] << { :line => line_range.next, :content => line_content[1] }
           end
         end
       end
     end
   end
  end

  def rangify string
    Generator.new lambda { |s| s.first..s.last }.call string.split(',').map(&:to_i)
  end

  def difference_rangify *strings
    s1, s2 = strings.map{|s| s.split(',').map(&:to_i) }
    return [] if s1.reduce(:-) == s2.reduce(:-) || s1.size == 1 && s2.size == 1
    start_difference =  s2.first - s1.first
    (s2.last+1+start_difference)..s1.last
  end

  def git_diff
    raw = `git diff --no-index #{@file1} #{@file2}`
    line_no = 0
    save_point = nil
    in_parsing_region = nil
    sequence = nil

    {}.tap do |rethash|
      rethash[:additions] = []
      rethash[:deletions] = []
      raw.each_line do |line|
        if match = line.match(/@@ -(\d+),\d+ \+\d+,\d+ @@/)
          line_no = Integer(match[1])
          in_parsing_region ||= true
        elsif !in_parsing_region
          next
        elsif match = line.match(/(\+|-)(.*)/)
          case match[1]
          when('-')
            save_point ||= line_no
            if sequence != :deletions && save_point
              line_no = save_point
            end
            rethash[:deletions] << { :line => line_no, :content => match[2] }
            sequence = :deletions
          when('+')
            if sequence != :additons && save_point
              line_no = save_point
            end
            rethash[:additions] << { :line => line_no, :content => match[2] }
            sequence = :additions
          end
          line_no += 1
        else
          if save_point
            line_no = save_point + 1
            save_point = nil
          end
          sequence = nil
          line_no += 1
        end
      end
    end
  end

end
