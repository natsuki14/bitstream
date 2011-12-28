require 'bitstream'

class Gzip
  
  include BitStream
  byte_order :little_endian

  FHCRC    = 1 << 1
  FEXTRA   = 1 << 2
  FNAME    = 1 << 3
  FCOMMENT = 1 << 4

  fields do
    unsigned :id1,   8
    unsigned :id2,   8
    unsigned :cm,    8
    unsigned :flg,   8
    unsigned :mtime, 32
    unsigned :xfl,   8
    unsigned :os,    8
    if (flg & FEXTRA) != 0
      unsigned :xlen, 16
      string   :extra_field, xlen
    end
    if (flg & FNAME) != 0
      # cstring means a NULL-terminated string.
      cstring :original_file_name
    end
    if (flg & FCOMMENT) != 0
      # cstring means a NULL-terminated string.
      cstring :file_comment
    end
    if (flg & FHCRC) != 0
      unsigned :crc16, 16
    end
  end

end
