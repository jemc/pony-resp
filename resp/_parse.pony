use "buffered"

primitive _Parse
  fun bulk_string(buf: Reader, err_fn: {(String)} ref, size: USize): String? =>
    // Don't proceed unless we have enough bytes for the string and terminator.
    if buf.size() < (size + 2) then error end
    
    // Consume the bytes and line terminator.
    let bytes = buf.block(size)?
    if (buf.u8()? != '\r') or (buf.u8()? != '\n') then
      proto_err(err_fn, "bulk string not terminated as expected")?
    end
    
    String.from_array(consume bytes)
  
  fun usize(buf: Reader, err_fn: {(String)} ref, offset': USize): USize? =>
    u64(buf, err_fn, offset')?.usize()
  
  fun i64(buf: Reader, err_fn: {(String)} ref, offset': USize): I64? =>
    // Handle an optional negative marker, then proceed to parse the digits.
    if buf.peek_u8(offset')? == '-'
    then u64(buf, err_fn, offset' + 1)?.i64() * -1
    else u64(buf, err_fn, offset')?.i64()
    end
  
  fun u64(buf: Reader, err_fn: {(String)} ref, offset': USize): U64? =>
    var offset = offset'
    var result = U64(0)
    var byte   = buf.peek_u8(offset = offset + 1)?
    
    // Peek at each byte until we see the line terminator, getting the value
    // of each byte as a decimal digit and accumulating the result value.
    while byte != '\r' do
      let digit = (byte = buf.peek_u8(offset = offset + 1)?) - '0'
      let prev_result = result = (result * 10) + digit.u64()
      
      if digit > 9 then
        byte = digit + '0'
        proto_err(err_fn, "unknown digit byte: " + String.>push(byte))?
      elseif prev_result > result then
        proto_err(err_fn, "64-bit integer overflow")?
      end
    end
    
    // Expect the next byte to be te second byte of the line terminator.
    byte = buf.peek_u8(offset = offset + 1)?
    if byte != '\n' then
      proto_err(err_fn, "expected newline, got: " + String.>push(byte))?
    end
    
    // Move past all the bytes that we peeked at.
    buf.skip(offset)?
    
    result
  
  fun proto_err(err_fn: {(String)} ref, message: String) ? =>
    err_fn("BADPROTOCOL " + message)
    error
