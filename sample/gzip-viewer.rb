require_relative 'gzip'

gzip = nil
File.open(ARGV[0], "rb") do |file|
  gzip = Gzip.create(file.read)
end

if gzip.respond_to? :original_file_name
  puts "original_file_name:#{gzip.original_file_name}"
else
  puts "The gzip does not contain its original file name."
end
