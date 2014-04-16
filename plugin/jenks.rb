module Jenks

  def cluster data, no_of_classes
    no_of_classes = data.length  if data.length < no_of_classes
    sorted_data = data.sort
    min_val = sorted_data.first
    sorted_data.map! { |datum| datum - min_val }
    breaks = get_breaks(sorted_data, no_of_classes).uniq.sort

    result = Array.new breaks.length
    start = 0
    breaks.each_with_index do |b, i|
      finish = sorted_data.rindex b
      result[i] = sorted_data[start..finish]
      start = finish + 1
    end

    #de-normalize the data, and remove any empty clusters
    result.map!{ |cluster| cluster.map { |datum| datum + min_val } }
    return result.tap { |r| r.reject! { |c| c.empty? } }
  end

  def linear_cluster data, no_of_classes
    sorted_data = data.sort
    breaks = get_lin_breaks sorted_data, no_of_classes

    result = Array.new no_of_classes
    start = 0
    breaks.each_with_index do |b, i|
      finish = find_last_index sorted_data, b
      result[i] = finish ? sorted_data[start..finish] : []
      start = finish ? finish + 1 : start
    end
    result.tap { |r| r.reject! { |c| c.empty? } }
  end

  def find_last_index data, val
    index = nil
    found = false
    data.each_with_index do |d, i|
      if d == val
        found = true if !found
      else
        return i-1 if found || d > val
      end
    end
    found ? data.size - 1 : nil
  end

  def get_breaks data, no_of_classes

    lower_class_limits = Array.new(data.length + 2) { Array.new(no_of_classes + 2, 0) }
    variance_combinations = Array.new(data.length + 2) { Array.new(no_of_classes + 2, 0) }
    st = Array.new(data.length) { 0 }

    #
    (1..no_of_classes+1).each do |i|
      lower_class_limits[1][i] = 1;
      variance_combinations[1][i] = 0;
      (2..data.length+1).each do |j|
        variance_combinations[j][i] = Float::MAX
      end
    end

    variance = 0.0
    (2..data.length).each do |l|
      sum = 0.0
      sum_squares = 0.0
      w  = 0.0

      (1..l).each do |m|
        lower_class_limit = l - m + 1

        val = data[lower_class_limit - 1]

        sum_squares += val * val
        sum += val

        w += 1
        variance = sum_squares - (sum * sum) / w
        i4 = lower_class_limit - 1
        if i4 != 0
          (2..no_of_classes).each do |j|
            if variance_combinations[l][j] >= (variance + variance_combinations[i4][j - 1])
              lower_class_limits[l][j] = lower_class_limit
              variance_combinations[l][j] = variance + variance_combinations[i4][j - 1]
            end
          end
        end
      end
      lower_class_limits[l][1] = 1
      variance_combinations[l][1] = variance
    end

    k = data.size

    kclass = Array.new no_of_classes
    kclass[no_of_classes-1] = data[data.size - 1]

    no_of_classes.downto(2).each do |j|
      id = lower_class_limits[k][j] - 2
      kclass[j - 2] = data[id]
      k = lower_class_limits[k][j] - 1
    end

    kclass
  end

  def get_lin_breaks data, no_of_classes
    range = data.last - data.first

    kclass = Array.new(no_of_classes)
    (0..no_of_classes-2).each do |i|
      kclass[i] = (range / no_of_classes) * (i + 1)
    end
    kclass[no_of_classes-1] = data.last
    kclass
  end

  extend self
end
