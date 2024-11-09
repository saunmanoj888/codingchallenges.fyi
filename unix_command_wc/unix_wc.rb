# ccwc tool implementation in Ruby with -c (bytes), -l (lines), -w (words), and default (all) options
def ccwc(option, filename)
  # Check if the option is valid, or if no option is provided (default behavior)
  unless %w[-c -l -w].include?(option) || option.nil?
    puts "Invalid option. Use -c to count bytes, -l to count lines, -w to count words, or no option for all."
    return
  end

  # Check if the file exists and is readable
  unless File.exist?(filename)
    puts "Error: File '#{filename}' not found."
    return
  end

  unless File.readable?(filename)
    puts "Error: File '#{filename}' is not readable."
    return
  end

  # Calculate counts based on the option
  if option == "-c"
    byte_count = File.size(filename)
    puts "  #{byte_count} #{filename}"
  elsif option == "-l"
    line_count = File.foreach(filename).count
    puts "  #{line_count} #{filename}"
  elsif option == "-w"
    word_count = File.foreach(filename).reduce(0) { |count, line| count + line.split.size }
    puts "  #{word_count} #{filename}"
  else
    # Default behavior: calculate all counts
    line_count = File.foreach(filename).count
    word_count = File.foreach(filename).reduce(0) { |count, line| count + line.split.size }
    byte_count = File.size(filename)
    puts "  #{line_count} #{word_count} #{byte_count} #{filename}"
  end
end

# Usage example
option = ARGV[0]&.start_with?("-") ? ARGV[0] : nil # First command-line argument (e.g., "-c", "-l", or "-w"), or nil for default
filename = ARGV[1] || ARGV[0]  # Second command-line argument (filename) or the first if no option is provided

ccwc(option, filename)
