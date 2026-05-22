#!/usr/bin/env ruby
# Add optional: true to all belongs_to associations that don't already have optional: or required:
# This is safe for Rails 5 migration

converted_files = 0
converted_lines = 0

Dir.glob('app/models/**/*.rb').each do |path|
  content = File.read(path)
  new_content = content.gsub(/^(\s*belongs_to\s+.+)$/) do |line|
    # Skip lines that already have optional: or required:
    if line.include?('optional:') || line.include?('required:')
      line
    else
      converted_lines += 1
      # Insert optional: true before end-of-line (handling trailing whitespace/comments)
      # Pattern: belongs_to :name, ...options...  => belongs_to :name, optional: true, ...options...
      # Or: belongs_to :name => belongs_to :name, optional: true
      if line =~ /^(\s*belongs_to\s+:\w+)\s*$/
        # belongs_to :name with nothing else
        "#{$1}, optional: true"
      elsif line =~ /^(\s*belongs_to\s+:\w+)(,\s*)(.+)$/
        # belongs_to :name, ...rest...
        "#{$1}, optional: true,#{$2}#{$3}"
      else
        # Fallback: append at end
        line.rstrip + ', optional: true'
      end
    end
  end
  if new_content != content
    File.write(path, new_content)
    converted_files += 1
    puts "Updated: #{path}"
  end
end

puts "\nTotal: #{converted_files} files, #{converted_lines} belongs_to lines updated"
