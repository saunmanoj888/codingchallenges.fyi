# Custom cut tool implementation in Ruby
def cut_f2(filename, field_option, delimiter = "  ")
  # Extract field number from option, e.g., "-f2" -> 2
  field_numbers = field_option.match(/-f\s*["']?([\d,\s]+)["']?/)[1].split(/[, ]+/).map { |num| num.to_i - 1 }  # Convert to zero-based indices


  File.foreach(filename) do |line|
    fields = line.chomp.split(delimiter)  # Split each line by specified delimiter

    # Select specified fields and join them with the same delimiter for output
    output = field_numbers.map { |index| fields[index] if index < fields.size }.compact.join(delimiter)
    puts output unless output.empty?
  end
end

# Usage example
filename = "sample.csv"
field_option = "-f2,3"
delimiter_option = ","
cut_f2(filename, field_option, delimiter_option)