module Jenks

  def cluster data, no_of_classes
    sorted_data = data.sort
    breaks = get_breaks sorted_data, no_of_classes

    result = Array.new no_of_classes
    start = 0
    breaks.each_with_index do |b, i|
      finish = sorted_data.rindex b
      result[i] = sorted_data[start..finish]
      start = finish + 1
    end
    result.tap { |r| r.reject! { |c| c.empty? } }
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

    mat1 = Array.new(data.length + 2) { Array.new(no_of_classes + 2, 0) }
    mat2 = Array.new(data.length + 2) { Array.new(no_of_classes + 2, 0) }
    st = Array.new(data.length) { 0 }

    (1..no_of_classes+1).each do |i|
      mat1[1][i] = 1;
      mat2[1][i] = 0;
      (2..data.length+1).each do |j|
        mat2[j][i] = Float::MAX
      end
    end

    v = 0.0
    (2..data.length).each do |l|
      s1 = 0.0
      s2 = 0.0
      w  = 0.0

      (1..l).each do |m|
        i3 = l - m + 1

        val = data[i3 - 1]

        s2 += val * val
        s1 += val

        w += 1
        v = s2 - (s1 * s1) / w
        i4 = i3 - 1
        if i4 != 0
          (2..no_of_classes).each do |j|
            if mat2[l][j] >= (v + mat2[i4][j - 1])
              mat1[l][j] = i3
              mat2[l][j] = v + mat2[i4][j - 1]
            end
          end
        end
      end
      mat1[l][1] = 1
      mat2[l][1] = v
    end

    k = data.size

    kclass = Array.new no_of_classes
    kclass[no_of_classes-1] = data[data.size - 1]

    no_of_classes.downto(2).each do |j|
      id = mat1[k][j] - 2
      kclass[j - 2] = data[id]
      k = mat1[k][j] - 1
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
