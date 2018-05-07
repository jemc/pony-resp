use buffered = "buffered"

class ref ResponseWriter
  embed buffer: buffered.Writer = buffer.create()
  
  fun ref apply(data: Data) =>
    """
    Write the given Data using the RESP protocol.
    """
    _ResponseWrite[buffered.Writer](buffer, data)
  
  fun ref err(message: String) =>
    """
    Write a RESP Error with the given message.
    """
    _ResponseWrite[buffered.Writer].err(buffer, message)
  
  fun ref simple(message: String) =>
    """
    Write a RESP Simple String with the given message.
    """
    _ResponseWrite[buffered.Writer].simple(buffer, message)
  
  fun ref ok() =>
    """
    Write a RESP Simple String with the "OK" message.
    
    This is slightly more performant and convenient than calling simple("OK").
    """
    _ResponseWrite[buffered.Writer].ok(buffer)
  
  fun ref string(value: String) =>
    """
    Write a RESP Bulk String with the given value.
    """
    _ResponseWrite[buffered.Writer].string(buffer, value)
  
  fun ref null() =>
    """
    Write a RESP Bulk String with a NULL value.
    """
    _ResponseWrite[buffered.Writer].null(buffer)
  
  fun ref null_array() =>
    """
    Write a RESP Array with a NULL value.
    
    The semantic meaning is identical to the null() method,
    so there is not much reason to use this method apart from legacy concerns.
    """
    _ResponseWrite[buffered.Writer].null_array(buffer)
  
  fun ref usize(value: USize) => _int[USize](value)
  fun ref ulong(value: ULong) => _int[ULong](value)
  fun ref u64  (value: U64)   => _int[U64]  (value)
  fun ref u32  (value: U32)   => _int[U32]  (value)
  fun ref u16  (value: U16)   => _int[U16]  (value)
  fun ref u8   (value: U8)    => _int[U8]   (value)
  
  fun ref isize(value: ISize) => _int[ISize](value)
  fun ref ilong(value: ILong) => _int[ILong](value)
  fun ref i64  (value: I64)   => _int[I64]  (value)
  fun ref i32  (value: I32)   => _int[I32]  (value)
  fun ref i16  (value: I16)   => _int[I16]  (value)
  fun ref i8   (value: I8)    => _int[I8]   (value)
  
  fun ref _int[A: (Integer[A] val & (Signed | Unsigned))](value: A) =>
    """
    Write a RESP Integer containing the given value.
    """
    _ResponseWrite[buffered.Writer]._int[A](buffer, value)
  
  fun ref f64(value: F64) => _float[F64](value)
  fun ref f32(value: F32) => _float[F32](value)
  
  fun ref _float[A: (FloatingPoint[A] & Float)](value: A) =>
    """
    Write a RESP Bulk String containing the given value as a string.
    """
    _ResponseWrite[buffered.Writer]._float[A](buffer, value)
  
  fun ref array_start(size: USize) =>
    """
    Write the starting header of a RESP Array, indicating the number of elements.
    
    The elements of the array are expected to follow, numbering exactly
    the same as the given array size. Nested arrays count as a single element
    from the perspective of the outer context that contains them.
    """
    _ResponseWrite[buffered.Writer].array_start(buffer, size)
