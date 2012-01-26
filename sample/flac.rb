require 'bitstream'

class FLAC

  include BitStream

  class MetadataBlock

    include BitStream

    #add_type MetadataBlockData

    fields do
      unsigned_int :last_metadata_block, 1
      unsigned_int :block_type, 7
      unsigned_int :body_length, 24
      string :data, body_length
    end

    def length
      32 + body_length
    end
    
  end

  add_type MetadataBlock

  fields do
    string :magic, 4#, "The FLAC stream marker"
    dyn_array :metadata_blocks, :metadata_block
    unless metadata_blocks.last.last_metadata_block
      dyn_array :metadata_blocks, :metadata_block
        #, "The basic property of the stream."
    end
  end

end
