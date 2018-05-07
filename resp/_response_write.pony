primitive _ResponseWrite[O: ((OutAsync tag | OutSync ref) & Any #alias)]
  fun _write(out: O, data: String) =>
    // TODO: figure out how to avoid this workaround:
    iftype O <: OutAsync tag then out.write(data)
    elseif O <: OutSync ref  then out.write(data)
    else None // TODO: figure out how to disallow reifying with the union type
    end
  
  fun _writev(out: O, data: Array[String] val) =>
    // TODO: figure out how to avoid this workaround:
    iftype O <: OutAsync tag then out.writev(data)
    elseif O <: OutSync ref  then out.writev(data)
    else None // TODO: figure out how to disallow reifying with the union type
    end
  
  fun apply(out: O, data: Data) =>
    match data
    | let _: None        => null(out)
    | let _: OK          => ok(out)
    | let e: Error       => err(out, e.message)
    | let s: String      => string(out, s)
    | let i: I64         => i64(out, i)
    | let e: ElementsAny =>
      array_start(out, e.size())
      for v in e.values() do
        apply(out, v)
      end
    end
  
  fun err(out: O, message: String) =>
    _writev(out, ["-"; message; "\r\n"])
  
  fun simple(out: O, message: String) =>
    _writev(out, ["+"; message; "\r\n"])
  
  fun ok(out: O) =>
    _write(out, "+OK\r\n")
  
  fun string(out: O, value: String) =>
    _string_start(out, value.size())
    _writev(out, [value; "\r\n"])
  
  fun null(out: O) =>
    _write(out, "$-1\r\n")
  
  fun null_array(out: O) =>
    _write(out, "*-1\r\n")
  
  fun usize(out: O, value: USize) => _int[USize](out, value)
  fun ulong(out: O, value: ULong) => _int[ULong](out, value)
  fun u64  (out: O, value: U64)   => _int[U64]  (out, value)
  fun u32  (out: O, value: U32)   => _int[U32]  (out, value)
  fun u16  (out: O, value: U16)   => _int[U16]  (out, value)
  fun u8   (out: O, value: U8)    => _int[U8]   (out, value)
  
  fun isize(out: O, value: ISize) => _int[ISize](out, value)
  fun ilong(out: O, value: ILong) => _int[ILong](out, value)
  fun i64  (out: O, value: I64)   => _int[I64]  (out, value)
  fun i32  (out: O, value: I32)   => _int[I32]  (out, value)
  fun i16  (out: O, value: I16)   => _int[I16]  (out, value)
  fun i8   (out: O, value: I8)    => _int[I8]   (out, value)
  
  fun _int[A: (Integer[A] val & (Signed | Unsigned))](out: O, value: A) =>
    let zero = A.from[U8](0) // TODO: avoid this workaround
    let one  = A.from[U8](1) // TODO: avoid this workaround
    
    if     value == zero then _write(out, ":0\r\n")
    elseif value == one  then _write(out, ":1\r\n")
    else                      _writev(out, [":"; value.string(); "\r\n"])
    end
  
  fun f64(out: O, value: F64) => _float[F64](out, value)
  fun f32(out: O, value: F32) => _float[F32](out, value)
  
  fun _float[A: (FloatingPoint[A] & Float)](out: O, value: A) =>
    if not value.finite() then
      if     value.nan()            then _write(out, "$3\r\nnan\r\n")
      elseif value > A.from[F32](0) then _write(out, "$3\r\ninf\r\n")
      else                               _write(out, "$4\r\n-inf\r\n")
      end
    else
      string(out, value.string())
    end
  
  fun array_start(out: O, size: USize) =>
    if size < 32 then
      // Optimize writing common values, using the string table of the binary
      // instead of allocating a new string at runtime for every occurrence.
      _write(out, 
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
      _writev(out, ["*"; size.string(); "\r\n"])
    end
  
  fun _string_start(out: O, size: USize) =>
    if size < 32 then
      // Optimize writing common values, using the string table of the binary
      // instead of allocating a new string at runtime for every occurrence.
      _write(out, 
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
      _writev(out, ["$"; size.string(); "\r\n"])
    end
