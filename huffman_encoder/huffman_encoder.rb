#!/usr/bin/env ruby
require 'pqueue'
require 'optparse'

# Node class for building Huffman Tree
class Node
  attr_accessor :char, :frequency, :left, :right

  def initialize(char, frequency)
    @char = char
    @frequency = frequency
    @left = nil
    @right = nil
  end

  # Comparison for priority queue
  def <=>(other)
    frequency <=> other.frequency
  end
end

class HuffmanEncoder
  attr_reader :frequency_table, :root, :code_table

  def initialize(input_filename, output_filename)
    @input_filename = input_filename
    @output_filename = output_filename
    @frequency_table = Hash.new(0)
    @code_table = {}
    @root = nil
  end

  # File validation and frequency calculation
  def validate_file
    unless File.exist?(@input_filename) && File.readable?(@input_filename)
      raise "Error: File does not exist or is not readable."
    end

    true
  end

  def calculate_frequency
    File.read(@input_filename).each_char { |char| @frequency_table[char] += 1 }
  end

  # Build Huffman Tree using frequency table
  def build_huffman_tree
    # Priority queue for building the tree (min-heap)
    queue = PQueue.new(@frequency_table.map { |char, freq| Node.new(char, freq) }) { |a, b| a.frequency < b.frequency }

    while queue.size > 1
      left = queue.pop
      right = queue.pop

      merged = Node.new(nil, left.frequency + right.frequency)
      merged.left = left
      merged.right = right

      queue.push(merged)
    end

    @root = queue.pop
  end

  # Print tree structure for debugging (in-order traversal)
  def print_tree(node = @root, indent = 0)
    return unless node

    print_tree(node.right, indent + 4)
    puts ' ' * indent + (node.char ? "'#{node.char}': #{node.frequency}" : "Node: #{node.frequency}")
    print_tree(node.left, indent + 4)
  end

   # Generate prefix-code table from Huffman tree
   def generate_codes(node = @root, current_code = "")
    return if node.nil?

    if node.char # Leaf node, assign code to character
      @code_table[node.char] = current_code
    else
      # Traverse left and right, appending '0' or '1' respectively
      generate_codes(node.left, current_code + "0")
      generate_codes(node.right, current_code + "1")
    end
  end

  # Print prefix-code table for debugging
  def print_code_table
    puts "Character : Code"
    @code_table.each do |char, code|
      puts "'#{char}' : #{code}"
    end
  end

  # Encode the input file and write the compressed data to the output file
  def compress
    # Calculate frequency and build the tree and code table
    validate_file
    calculate_frequency
    build_huffman_tree
    generate_codes
    print_code_table

    # Write to output file with header and compressed data
    File.open(@output_filename, 'wb') do |file|
      write_header(file)
      write_compressed_data(file)
    end
    puts "File compressed and saved as #{@output_filename}"
  end

  # Write header with frequency table
  def write_header(file)
    header_data = @frequency_table.map { |char, freq| "#{char}:#{freq}" }.join(",")
    file.write(header_data + "\n--END HEADER--\n")
  end

  # Write compressed data using the code table
  def write_compressed_data(file)
    binary_data = ""

    File.read(@input_filename).each_char do |char|
      binary_data += @code_table[char]
    end

    # Ensure binary data length is a multiple of 8 by padding with 0s if necessary
    padding_length = (8 - binary_data.length % 8) % 8
    binary_data += "0" * padding_length

    puts "binary_data--->#{binary_data}"

    # Store the padding length as the first byte of the compressed data for decoding
    file.write([padding_length].pack("C"))

    # Write binary data as bytes
    file.write([binary_data].pack("B*"))
  end

  # Print prefix-code table for debugging (optional)
  def print_code_table
    puts "Character : Code"
    @code_table.each { |char, code| puts "'#{char}' : #{code}" }
  end
end

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby huffman_encoder.rb <input_filename> -o <output_filename>"

  opts.on("-o", "--output FILENAME", "Output compressed file") do |filename|
    options[:output] = filename
  end
end.parse!

input_filename = ARGV[0]
output_filename = options[:output]

if input_filename.nil? || output_filename.nil?
  puts "Usage: ruby huffman_encoder.rb <input_filename> -o <output_filename>"
  exit 1
end

# Run the compression
encoder = HuffmanEncoder.new(input_filename, output_filename)
encoder.compress



class HuffmanDecoder
  attr_reader :frequency_table, :root, :code_table

  def initialize(encoded_filename, output_filename)
    @encoded_filename = encoded_filename
    @output_filename = output_filename
    @frequency_table = {}
    @root = nil
    @code_table = {}
  end

  # Read the header and rebuild the frequency table
  def read_header(file)
    header_data = ""
    until (line = file.gets) == "--END HEADER--\n"
      header_data += line
    end

    # Parse frequency table from header data
    header_data.split(",").each do |entry|
      char, freq = entry.split(":")
      @frequency_table[char] = freq.to_i
    end
  end

  # Rebuild the Huffman tree from the frequency table
  def build_huffman_tree
    # Priority queue for building the tree (min-heap)
    queue = PQueue.new(@frequency_table.map { |char, freq| Node.new(char, freq) }) { |a, b| a.frequency < b.frequency }

    while queue.size > 1
      left = queue.pop
      right = queue.pop

      merged = Node.new(nil, left.frequency + right.frequency)
      merged.left = left
      merged.right = right

      queue.push(merged)
    end

    @root = queue.pop
  end

  # Generate prefix-code table from the Huffman tree
  def generate_codes(node = @root, current_code = "")
    return if node.nil?

    if node.char # Leaf node, assign code to character
      @code_table[node.char] = current_code
    else
      # Traverse left and right, appending '0' or '1' respectively
      generate_codes(node.left, current_code + "0")
      generate_codes(node.right, current_code + "1")
    end
  end

  # Main method to decode the compressed file
  def decode
    File.open(@encoded_filename, 'rb') do |file|
      read_header(file)
      build_huffman_tree
      generate_codes
      puts "Frequency Table: #{@frequency_table}"  # Debugging output
      puts "Code Table: #{@code_table}"            # Debugging output
      decode_data(file)
    end
    puts "File decoded and saved as #{@output_filename}"
  end

  # Decode the compressed data and write to output file
  def decode_data(file)
    # Read the padding length
    padding_length = file.read(1).unpack1("C")
    puts "Padding length: #{padding_length}"  # Debugging output

    # Read the remaining binary data
    binary_data = file.read.unpack1("B*")
    puts "Binary data (before padding trim): #{binary_data}"  # Debugging output

    # Remove padding bits at the end based on padding length
    binary_data = binary_data[0...-padding_length] if padding_length > 0
    puts "Binary data (after padding trim): #{binary_data}"  # Debugging output

    # Decode the binary data using the Huffman tree
    decoded_text = ""
    current_node = @root

    binary_data.each_char do |bit|
      # Traverse left or right based on the current bit
      current_node = bit == "0" ? current_node.left : current_node.right

      # If we reach a leaf node, append the character and reset
      if current_node.char
        decoded_text += current_node.char
        current_node = @root
      end
    end

    puts "Decoded text: #{decoded_text}"  # Debugging output

    # Write decoded text to the output file
    File.write(@output_filename, decoded_text)
  end
end

# Usage example
encoded_filename = "compressed_output.huff"
output_filename = "decompressed_output.txt"
decoder = HuffmanDecoder.new(encoded_filename, output_filename)
decoder.decode