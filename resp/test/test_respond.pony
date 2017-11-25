use "ponytest"
use ".."

actor _TestRespondWith
  let h: TestHelper
  let expected: String
  let received: String ref = String
  
  new create(h': TestHelper, expected': String) =>
    (h, expected) = (h', expected')
    h.expect_action(expected)
  
  be writev(data: ByteSeqIter) => for d in data.values() do _write(d) end
  be write(data: ByteSeq) => _write(data)
  
  fun ref _write(data: ByteSeq) => received.append(data); _check_complete()
  fun ref _check_complete() =>
    if received.size() >= expected.size() then
      h.assert_eq[String box](expected, received)
      h.complete_action(expected)
    end

class TestRespond is UnitTest
  fun name(): String => "resp.Respond"
  
  fun _test(h: TestHelper, s: String): Respond =>
    Respond(_TestRespondWith(h, s))
  
  fun apply(h: TestHelper) =>
    h.long_test(5_000_000_000)
    
    _test(h, "-WRONGTHING something went wrong\r\n")
      .> err("WRONGTHING something went wrong")
    
    _test(h, "+NOPROBLEM\r\n")
      .> simple("NOPROBLEM")
    
    _test(h, "+OK\r\n")
      .> ok()
    
    _test(h, "$5\r\nVALUE\r\n")
      .> string("VALUE")
    
    _test(h, "$17\r\nMULTI-LINE\r\nVALUE\r\n")
      .> string("MULTI-LINE\r\nVALUE")
    
    _test(h, "$-1\r\n")
      .> null()
    
    _test(h, "*-1\r\n")
      .> null_array()
    
    _test(h, ":-1\r\n")
      .> i64(-1)
    
    _test(h, ":1\r\n")
      .> i64(1)
    
    _test(h, ":99\r\n")
      .> i64(99)
    
    _test(h, "$3\r\n9.9\r\n")
      .> f64(9.9)
    
    _test(h, "$3\r\nnan\r\n")
      .> f64(0 / 0)
    
    _test(h, "$3\r\ninf\r\n")
      .> f64(1 / 0)
    
    _test(h, "$4\r\n-inf\r\n")
      .> f64(-1 / 0)
    
    _test(h, "*3\r\n$3\r\nRED\r\n$5\r\nGREEN\r\n$4\r\nBLUE\r\n")
      .> array_start(3)
      .> string("RED")
      .> string("GREEN")
      .> string("BLUE")
