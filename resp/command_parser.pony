use "buffered"
use "collections"
use "debug"

class ref CommandParser is Iterator[Array[String] val]
  """
  A more limited (but more efficient) version of Parser that only parses
  Arrays of strings (RESP commands), and outputs them as Array[String] val.
  """
  embed _buf:      Reader                   = _buf.create()
  embed _commands: Array[Array[String] trn] = []
  var   _command:  Array[String] trn        = []
  
  let _proto_err_fn: {(String)} ref
  var _expect_string: USize = -1
  var _expect_array:  USize = -1
  
  new create(proto_err_fn': {(String)} ref) => _proto_err_fn = proto_err_fn'
  fun ref _proto_err(m: String) ? => _Parse.proto_err(_proto_err_fn, m)?
  
  fun ref append(data: ByteSeq) =>
    // TODO: as an optimization, if _buf is empty, we could in some cases
    // parse the incoming string directly without pushing onto the buffer.
    _buf.append(data)
    _buf_to_commands()
  
  fun ref has_next(): Bool => _commands.size() > 0
  fun ref next(): Array[String] val? => _commands.shift()?
  
  fun ref _buf_to_commands() =>
    try while _buf.size() > 0 do
      if _expect_string != -1 then
        _command.push(_Parse.bulk_string(_buf, _proto_err_fn, _expect_string)?)
        _expect_string = -1
        if _command.size() >= _expect_array then
          _expect_array = -1
          _commands.push(_command = [])
        end
      else
        let byte = _buf.peek_u8()?
        if _expect_array != -1 then
          if _buf.peek_u8()? == '$' then
            _expect_string = _Parse.usize(_buf, _proto_err_fn, 1)?
          else
            _proto_err("'$' byte expected, but got: " + String.>push(byte))?
          end
        else
          if _buf.peek_u8()? == '*' then
            _expect_array = _Parse.usize(_buf, _proto_err_fn, 1)?
          else
            _proto_err("'*' byte expected, but got: " + String.>push(byte))?
          end
        end
      end
    end end
