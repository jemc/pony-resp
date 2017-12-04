use "buffered"
use "collections"

class ref Parser is Iterator[Data]
  embed _buf:    Reader        = _buf.create()
  embed _tokens: Array[_Token] = _tokens.create()
  
  let _proto_err_fn: {(String)} ref
  var _need_extra_tokens: USize = 0
  var _expect_string:     USize = -1
  
  new create(proto_err_fn': {(String)} ref) => _proto_err_fn = proto_err_fn'
  fun ref _proto_err(m: String) ? => _Parse.proto_err(_proto_err_fn, m)?
  
  fun ref append(data: ByteSeq) =>
    // TODO: as an optimization, if _buf is empty, we could in some cases
    // parse the incoming string directly without pushing onto the buffer.
    _buf.append(data)
    _buf_to_tokens()
  
  fun ref has_next(): Bool => _tokens.size() > _need_extra_tokens
  fun ref next(): Data? =>
    // Only proceed if we're sure we have enough tokens to get a full result.
    if not has_next() then error end
    
    // Grab the first token from our list, being done if it's a simple token,
    // or proceeding to the _next_elements if it is a RESP array size marker.
    let iter = _tokens.values()
    (let data, let consumed_tokens) =
      match iter.next()?
      | let size: USize => _next_elements(iter, size)?
      | let data: Data  => (data, 1)
      end
    _tokens.remove(0, consumed_tokens)
    _need_extra_tokens = _need_extra_tokens - (consumed_tokens - 1)
    data
  
  fun tag _next_elements(
    iter: Iterator[_Token],
    size': USize)
  : (ElementsAny, USize)? =>
    // Accumulate the next sequence of tokens into an elements list.
    let elements = Elements
    var consumed_tokens: USize = 1
    for _ in Range(0, size') do
      // Grab the next token from our list, being done if it's a simple token,
      // or proceeding to the _next_elements if it is a RESP array size marker.
      // The simple token or elements list gets added to our own elements list.
      match iter.next()?
      | let size: USize =>
        let tuple = _next_elements(iter, size)?
        consumed_tokens = consumed_tokens + tuple._2
        elements.push(tuple._1)
      | let data: Data =>
        consumed_tokens = consumed_tokens + 1
        elements.push(data)
      end
    end
    (consume elements, consumed_tokens)
  
  fun ref _buf_to_tokens() =>
    try while _buf.size() > 0 do
      if _expect_string != -1 then
        _tokens.push(_Parse.bulk_string(_buf, _proto_err_fn, _expect_string)?)
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
        | ':' => _tokens.push(_Parse.i64(_buf, _proto_err_fn, 1)?)
        | '$' =>
          if (_buf.peek_u8(1)? == '-')
          and (_buf.peek_u32_be(1)? == 0x2d310d0a) // "-1\r\n"
          then _tokens.push(None); _buf.skip(5)?
          else _expect_string = _Parse.usize(_buf, _proto_err_fn, 1)?
          end
        | '*' =>
          if (_buf.peek_u8(1)? == '-')
          and (_buf.peek_u32_be(1)? == 0x2d310d0a) // "-1\r\n"
          then _tokens.push(None); _buf.skip(5)?
          else
            let count = _Parse.usize(_buf, _proto_err_fn, 1)?
            _tokens.push(count)
            _need_extra_tokens = _need_extra_tokens + count
          end
        else
          _proto_err("unknown start byte: " + String.>push(byte))?
        end
      end
    end end
