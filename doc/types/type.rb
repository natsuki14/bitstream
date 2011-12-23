# -*- coding: utf-8 -*-

module BitStream

  # Dummy class for rdoc.
  class Type

    # インスタンスを生成します。
    # 引数 _params_ には、_BitStream.field_ メソッドのブロック内で指定された
    # 値が渡されます。
    def self.instance(*params)
    end

    # インスタンスの長さを返すメソッドです（単位はbit）。
    # 可変長フィールドでは _nil_ を返してください。
    def length
    end

    # _String_ として渡されたビットストリームを指定されたオフセット位置から解析し、
    # 値と長さを返すメソッドです。
    # _s_ :: ビットストリームが入った _String_ です。
    #        但し、_String_ と同じ振る舞いをする何かかもしれないので、
    #        Cで実装する場合は注意してください。
    # _offset_ :: 解析を始める位置をbit単位で示したものです。
    # Return :: 0番目に得られたオブジェクトを、
    #           1番目にそのビットストリーム上での長さをbit単位で収めた配列。
    #           _Type#length_ の戻り値が _nil_ でない場合、
    #           長さは、常に _Type#length_ と一致している必要があります。
    def read(s, offset)
    end

    # _String_ として渡されたビットストリームの指定された位置に、
    # _value_ を埋め込むメソッドです。
    # _s_ :: ビットストリームが入った _String_ です。
    #        但し、_String_ と同じ振る舞いをする何かかもしれないので、
    #        Cで実装する場合は注意してください。
    # _offset_ :: 埋め込む位置をbit単位で示したものです。
    # Return :: 埋め込んだオブジェクトの *ビットストリーム上* での長さです。
    #           _Type#length_ の戻り値が _nil_ でない場合、
    #           常に _Type#length_ と一致している必要があります。
    def write(s, offset, value)
    end

  end

end
