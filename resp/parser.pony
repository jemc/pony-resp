use "buffered"
use "collections"

class ref Parser is Iterator[Data]
  embed _buf:    Reader        = _buf.create()
  embed _tokens: Array[_Token] = _tokens.create()
  
  let _proto_err_fn: {(String)} ref
  var _expect_tokens: USize = 1
  var _expect_string: USize = -1
  
  new create(proto_err_fn': {(String)} ref) => _proto_err_fn = proto_err_fn'
  
  fun ref append(string: String) =>
    // TODO: as an optimization, if _buf is empty, we could in some cases
    // parse the incoming string directly without pushing onto the buffer.
    _buf.append(string)
    _buf_to_tokens()
  
  fun ref has_next(): Bool => _tokens.size() >= _expect_tokens
  fun ref next(): Data? =>
    // Only proceed if we're sure we have enough tokens to get a full result.
    if not has_next() then error end
    
    // Grab the first token from our list, being done if it's a simple token,
    // or proceeding to the _next_elements if it is a RESP array size marker.
    let iter = _tokens.values()
    let data =
      match iter.next()?
      | let size: USize => _next_elements(iter, size)?
      | let data: Data  => data
      end
    _tokens.remove(0, _expect_tokens)
    data
  
  fun _proto_err(message: String) ? =>
    _proto_err_fn("BADPROTOCOL " + message)
    error
  
  fun tag _next_elements(iter: Iterator[_Token], size': USize): ElementsAny? =>
    // Accumulate the next sequence of tokens into an elements list.
    let elements = Elements
    for _ in Range(0, size') do
      // Grab the next token from our list, being done if it's a simple token,
      // or proceeding to the _next_elements if it is a RESP array size marker.
      // The simple token or elements list gets added to our own elements list.
      match iter.next()?
      | let size: USize => elements.push(_next_elements(iter, size)?)
      | let data: Data  => elements.push(data)
      end
    end
    consume elements
  
  fun ref _buf_to_tokens() =>
    try while _buf.size() > 0 do
      if _expect_string != -1 then
        _tokens.push(_buf_as_bulk_string(_expect_string)?)
        _expect_string = -1
      else
        let byte = _buf.peek_u8()?
        match byte
        | '-' => _tokens.push(Error(_buf.line()?.trim(1)))
        | '+' =>
          if _buf.peek_u32_be(1 )? == 0x4f4b0d0a // "OK\r\n"
          then _tokens.push(OK); _buf.skip(5)?
          else _tokens.push(_buf.line()?.trim(1))
          end
        | ':' => _tokens.push(_buf_as_i64(1)?)
        | '$' =>
          if (_buf.peek_u8(1)? == '-')
          and (_buf.peek_u32_be(1)? == 0x2d310d0a) // "-1\r\n"
          then _tokens.push(None); _buf.skip(5)?
          else _expect_string = _buf_as_usize(1)?
          end
        | '*' =>
          if (_buf.peek_u8(1)? == '-')
          and (_buf.peek_u32_be(1)? == 0x2d310d0a) // "-1\r\n"
          then _tokens.push(None); _buf.skip(5)?
          else
            let count = _buf_as_usize(1)?
            _tokens.push(count)
            _expect_tokens = _expect_tokens + count
          end
        else
          _proto_err("unknown start byte: " + String.>push(byte))?
        end
      end
    end end
  
  fun ref _buf_as_bulk_string(size: USize): String? =>
    // Don't proceed unless we have enough bytes for the string and terminator.
    if _buf.size() < (size + 2) then error end
    
    // Consume the bytes and line terminator.
    let bytes = _buf.block(size)?
    if (_buf.u8()? != '\r') or (_buf.u8()? != '\n') then
      _proto_err("bulk string not terminated as expected")?
    end
    
    String.from_array(consume bytes)
  
  fun ref _buf_as_usize(offset: USize): USize? =>
    _buf_as_u64(offset)?.usize()
  
  fun ref _buf_as_i64(offset: USize): I64? =>
    // Handle an optional negative marker, then proceed to parse the digits.
    if _buf.peek_u8(offset)? == '-'
    then _buf_as_u64(offset + 1)?.i64() * -1
    else _buf_as_u64(offset)?.i64()
    end
  
  fun ref _buf_as_u64(offset': USize): U64? =>
    var offset = offset'
    var result = U64(0)
    var byte   = _buf.peek_u8(offset = offset + 1)?
    
    // Peek at each byte until we see the line terminator, getting the value
    // of each byte as a decimal digit and accumulating the result value.
    while byte != '\r' do
      let digit = (byte = _buf.peek_u8(offset = offset + 1)?) - '0'
      let prev_result = result = (result * 10) + digit.u64()
      
      if digit > 9 then
        byte = digit + '0'
        _proto_err("unknown digit byte: " + String.>push(byte))?
      elseif prev_result > result then
        _proto_err("64-bit integer overflow")?
      end
    end
    
    // Expect the next byte to be te second byte of the line terminator.
    byte = _buf.peek_u8(offset = offset + 1)?
    if byte != '\n' then
      _proto_err("expected newline, got: " + String.>push(byte))?
    end
    
    // Move past all the bytes that we peeked at.
    _buf.skip(offset)?
    
    result
