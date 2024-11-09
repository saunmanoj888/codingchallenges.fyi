class SimpleJSONParser
  def initialize(input)
    @input = input.strip
  end

  # Lexer to split the input into tokens (handling strings, booleans, null, numbers, colons, and braces)
  def tokenize
    tokens = []
    current_token = ''
    in_string = false

    @input.chars.each_with_index do |char, i|
      if char == '"'
        in_string = !in_string
        current_token += char
        if !in_string
          tokens << current_token
          current_token = ''
        end
      elsif in_string
        current_token += char
      elsif ['{', '}', ':', ','].include?(char)
        tokens << current_token unless current_token.empty?
        current_token = ''
        tokens << char
      elsif char =~ /\S/
        current_token += char
        if current_token == 'true' || current_token == 'false' || current_token == 'null'
          tokens << current_token
          current_token = ''
        elsif current_token.match?(/\A-?\d+(\.\d+)?\z/) && (i == @input.length - 1 || [' ', ',', '}'].include?(@input[i + 1]))
          tokens << current_token
          current_token = ''
        end
      end
    end
    tokens.reject(&:empty?)
  end

  # Parser to validate JSON structure with string, number, boolean, and null values
  def parse
    tokens = tokenize
    return false unless tokens.first == '{' && tokens.last == '}'

    tokens = tokens[1..-2] # Remove the opening and closing braces

    # Expect format ["string", ":", value] with commas separating pairs
    return false unless tokens.length >= 3

    while tokens.any?
      key = tokens.shift
      colon = tokens.shift
      value = tokens.shift

      # Check that key is a string and colon is `:`
      return false unless key.start_with?('"') && key.end_with?('"')
      return false unless colon == ':'

      # Validate the value type (string, number, boolean, or null)
      if value.start_with?('"') && value.end_with?('"') # String
        next
      elsif value.match?(/\A-?\d+(\.\d+)?\z/) # Number (integer or float)
        next
      elsif %w[true false null].include?(value) # Boolean or null
        next
      else
        return false
      end

      # Handle multiple key-value pairs (comma-separated)
      break if tokens.empty?
      comma = tokens.shift
      return false unless comma == ','
    end

    true
  end
end

# Main method to check the input and return appropriate message and exit code
def main
  input = ARGV[0] || ""
  
  parser = SimpleJSONParser.new(input)
  
  if parser.parse
    puts "Valid JSON"
    exit 0
  else
    puts "Invalid JSON"
    exit 1
  end
end

# Execute the main method if the script is run directly
main if __FILE__ == $PROGRAM_NAME