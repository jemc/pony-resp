class val Respond[O: OutAsync tag = OutAsync]
  let _out: O
  
  new val create(out': O) => _out = out'
  
  fun apply(data: Data) =>
    """
    Send the given Data using the RESP protocol.
    """
    _ResponseWrite[O](_out, data)
  
  fun err(message: String) =>
    """
    Send a RESP Error with the given message.
    """
    _ResponseWrite[O].err(_out, message)
  
  fun simple(message: String) =>
    """
    Send a RESP Simple String with the given message.
    """
    _ResponseWrite[O].simple(_out, message)
  
  fun ok() =>
    """
    Send a RESP Simple String with the "OK" message.
    
    This is slightly more performant and convenient than calling simple("OK").
    """
    _ResponseWrite[O].ok(_out)
  
  fun string(value: String) =>
    """
    Send a RESP Bulk String with the given value.
    """
    _ResponseWrite[O].string(_out, value)
  
  fun null() =>
    """
    Send a RESP Bulk String with a NULL value.
    """
    _ResponseWrite[O].null(_out)
  
  fun null_array() =>
    """
    Send a RESP Array with a NULL value.
    
    The semantic meaning is identical to the null() method,
    so there is not much reason to use this method apart from legacy concerns.
    """
    _ResponseWrite[O].null_array(_out)
  
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
    _ResponseWrite[O]._int[A](_out, value)
  
  fun f64(value: F64) => _float[F64](value)
  fun f32(value: F32) => _float[F32](value)
  
  fun _float[A: (FloatingPoint[A] & Float)](value: A) =>
    """
    Send a RESP Bulk String containing the given value as a string.
    """
    _ResponseWrite[O]._float[A](_out, value)
  
  fun array_start(size: USize) =>
    """
    Send the starting header of a RESP Array, indicating the number of elements.
    
    The elements of the array are expected to follow, numbering exactly
    the same as the given array size. Nested arrays count as a single element
    from the perspective of the outer context that contains them.
    """
    _ResponseWrite[O].array_start(_out, size)
