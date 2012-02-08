require './flac'

if ARGV.size != 1
  STDERR.puts "Usage: #{__FILE__} flac_file"
  exit 1
end

flac = FLAC.create(ARGV[0])
