use "ponytest"
use ".."

class TestParser is UnitTest
  fun name(): String => "resp.Parser"
  
  fun _test[A: Data](
    h: TestHelper,
    expected: A,
    input': String,
    loc: SourceLoc = __loc)
  =>
    let input = Array[String]
    for byte in input'.values() do
      input.push(recover String.>push(byte) end)
    end
    
    let parser = Parser({(err) => h.fail(err) })
    
    for string in input.values() do
      h.assert_false(parser.has_next(),
        "expected has_next to be false before chunk: " + string, loc)
      
      h.assert_false(try parser.next()?; true else false end,
        "expected parsing to be incomplete before chunk: " + string, loc)
      
      parser.append(string)
    end
    
    try
      h.assert_true(parser.has_next(),
        "expected has_next to be true for: " + expected.string(), loc)
      
      let actual = parser.next()?
      
      h.assert_eq[String](expected.string(), actual.string())
      
      try actual as A else
        h.assert_true(false,
          "expected data to be the right type: " + actual.string(), loc)
      end
    else
      h.assert_true(false,
        "expected parsing to be complete for: " + expected.string(), loc)
    end
    
    h.assert_false(parser.has_next(),
      "expected has_next to be false after: " + expected.string(), loc)
  
  fun apply(h: TestHelper) =>
    _test[Error](h,
      Error("WRONGTHING something went wrong"),
      "-WRONGTHING something went wrong\r\n")
    
    _test[String](h,
      "NOPROBLEM",
      "+NOPROBLEM\r\n")
    
    _test[OK](h,
      OK,
      "+OK\r\n")
    
    _test[String](h,
      "VALUE",
      "$5\r\nVALUE\r\n")
    
    _test[String](h,
      "MULTI-LINE\r\nVALUE",
      "$17\r\nMULTI-LINE\r\nVALUE\r\n")
    
    _test[None](h,
      None,
      "$-1\r\n")
    
    _test[None](h,
      None,
      "*-1\r\n")
    
    _test[I64](h,
      0,
      ":0\r\n")
    
    _test[I64](h,
      -1,
      ":-1\r\n")
    
    _test[I64](h,
      1,
      ":1\r\n")
    
    _test[I64](h,
      99,
      ":99\r\n")
    
    _test[String](h,
      "9.9",
      "$3\r\n9.9\r\n")
    
    _test[String](h,
      "nan",
      "$3\r\nnan\r\n")
    
    _test[Elements](h,
      recover Elements end,
      "*0\r\n")
    
    _test[Elements](h,
      recover
        Elements
          .> push(-1)
          .> push(0)
          .> push(1)
      end,
      "*3\r\n:-1\r\n:0\r\n:1\r\n")
    
    _test[Elements](h,
      recover
        Elements
          .> push("RED")
          .> push("GREEN")
          .> push("BLUE")
      end,
      "*3\r\n$3\r\nRED\r\n$5\r\nGREEN\r\n$4\r\nBLUE\r\n")
    
    _test[Elements](h,
      recover
        Elements
          .> push(recover Elements.>push("RED") end)
          .> push(recover Elements.>push("GREEN") end)
          .> push(recover Elements.>push("BLUE") end)
      end,
      "*3\r\n*1\r\n$3\r\nRED\r\n*1\r\n$5\r\nGREEN\r\n*1\r\n$4\r\nBLUE\r\n")
