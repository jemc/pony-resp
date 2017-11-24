
interface tag _Out
  be write(data: ByteSeq)
  be writev(data: ByteSeqIter)

class val Respond
  let _out: _Out
  
  new val create(out': _Out) => _out = out'
  
  fun err(message: String) =>
    """
    Send a RESP Error with the given message.
    """
    _out.writev(["-"; message; "\r\n"])
  
  fun simple(message: String) =>
    """
    Send a RESP Simple String with the given message.
    """
    _out.writev(["+"; message; "\r\n"])
  
  fun ok() =>
    """
    Send a RESP Simple String with the "OK" message.
    
    This is slightly more performant and convenient than calling simple("OK").
    """
    _out.write("+OK\r\n")
  
  fun string(value: String) =>
    """
    Send a RESP Bulk String with the given value.
    """
    _string_start(value.size())
    _out.writev([value; "\r\n"])
  
  fun null() =>
    """
    Send a RESP Bulk String with a NULL value.
    """
    _out.write("$-1\r\n")
  
  fun null_array() =>
    """
    Send a RESP Array with a NULL value.
    
    The semantic meaning is identical to the null() method,
    so there is not much reason to use this method apart from legacy concerns.
    """
    _out.write("*-1\r\n")
  
  fun usize(value: USize) => _int[USize](value)
  fun ulong(value: ULong) => _int[ULong](value)
  fun u64  (value: U64)   => _int[U64]  (value)
  fun u32  (value: U32)   => _int[U32]  (value)
  fun u16  (value: U16)   => _int[U16]  (value)
  fun u8   (value: U8)    => _int[U8]   (value)
  
  fun isize(value: ISize) => _int[ISize](value)
  fun ilong(value: ILong) => _int[ILong](value)
  fun i64  (value: I64)   => _int[I64]  (value)
  fun i32  (value: I32)   => _int[I32]  (value)
  fun i16  (value: I16)   => _int[I16]  (value)
  fun i8   (value: I8)    => _int[I8]   (value)
  
  fun _int[A: (Integer[A] val & (Signed | Unsigned))](value: A) =>
    """
    Send a RESP Integer containing the given value.
    """
    let zero = A.from[U8](0) // TODO: avoid this workaround
    let one  = A.from[U8](1) // TODO: avoid this workaround
    
    if     value == zero then _out.write(":0\r\n")
    elseif value == one  then _out.write(":1\r\n")
    else                      _out.writev([":"; value.string(); "\r\n"])
    end
  
  fun f64(value: F64) => _float[F64](value)
  fun f32(value: F32) => _float[F32](value)
  
  fun _float[A: (FloatingPoint[A] & Float)](value: A) =>
    """
    Send a RESP Bulk String containing the given value as a string.
    """
    if not value.finite() then
      if     value.nan()            then _out.write("$3\r\nnan\r\n")
      elseif value > A.from[F32](0) then _out.write("$3\r\ninf\r\n")
      else                               _out.write("$4\r\n-inf\r\n")
      end
    else
      string(value.string()) // TODO: consider a different float formatting
    end
  
  fun array_start(size: USize) =>
    """
    Send the starting header of a RESP Array, indicating the number of elements.
    
    The elements of the array are expected to follow, numbering exactly
    the same as the given array size. Nested arrays count as a single element
    from the perspective of the outer context that contains them.
    """
    if size < 32 then
      // Optimize writing common values, using the string table of the binary
      // instead of allocating a new string at runtime for every occurrence.
      _out.write(
        match size
        | 0  => "*0\r\n"  | 1  => "*1\r\n"  | 2  => "*2\r\n"  | 3  => "*3\r\n"
        | 4  => "*4\r\n"  | 5  => "*5\r\n"  | 6  => "*6\r\n"  | 7  => "*7\r\n"
        | 8  => "*8\r\n"  | 9  => "*9\r\n"  | 10 => "*10\r\n" | 11 => "*11\r\n"
        | 12 => "*12\r\n" | 13 => "*13\r\n" | 14 => "*14\r\n" | 15 => "*15\r\n"
        | 16 => "*16\r\n" | 17 => "*17\r\n" | 18 => "*18\r\n" | 19 => "*19\r\n"
        | 20 => "*20\r\n" | 21 => "*21\r\n" | 22 => "*22\r\n" | 23 => "*23\r\n"
        | 24 => "*24\r\n" | 25 => "*25\r\n" | 26 => "*26\r\n" | 27 => "*27\r\n"
        | 28 => "*28\r\n" | 29 => "*29\r\n" | 30 => "*30\r\n" | 31 => "*31\r\n"
        else "*0\r\n" // unreachable
        end
      )
    else
      _out.writev(["*"; size.string(); "\r\n"])
    end
  
  fun _string_start(size: USize) =>
    if size < 32 then
      // Optimize writing common values, using the string table of the binary
      // instead of allocating a new string at runtime for every occurrence.
      _out.write(
        match size
        | 0  => "$0\r\n"  | 1  => "$1\r\n"  | 2  => "$2\r\n"  | 3  => "$3\r\n"
        | 4  => "$4\r\n"  | 5  => "$5\r\n"  | 6  => "$6\r\n"  | 7  => "$7\r\n"
        | 8  => "$8\r\n"  | 9  => "$9\r\n"  | 10 => "$10\r\n" | 11 => "$11\r\n"
        | 12 => "$12\r\n" | 13 => "$13\r\n" | 14 => "$14\r\n" | 15 => "$15\r\n"
        | 16 => "$16\r\n" | 17 => "$17\r\n" | 18 => "$18\r\n" | 19 => "$19\r\n"
        | 20 => "$20\r\n" | 21 => "$21\r\n" | 22 => "$22\r\n" | 23 => "$23\r\n"
        | 24 => "$24\r\n" | 25 => "$25\r\n" | 26 => "$26\r\n" | 27 => "$27\r\n"
        | 28 => "$28\r\n" | 29 => "$29\r\n" | 30 => "$30\r\n" | 31 => "$31\r\n"
        else "$0\r\n" // unreachable
        end
      )
    else
      _out.writev(["$"; size.string(); "\r\n"])
    end
