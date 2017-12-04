use "ponytest"
use ".."

class TestCommandParser is UnitTest
  fun name(): String => "resp.CommandParser"
  
  fun apply(h: TestHelper) =>
    let parse = CommandParser({(_) => None })
    
    parse.append("*3\r\n$3\r\nRED\r\n$5\r\nGREEN\r\n$4\r\nBLUE\r\n")
    
    h.assert_array_eq[String](
      ["RED"; "GREEN"; "BLUE"],
      try parse.next()? else [] end)
    
    parse.append("*1\r\n$3\r\nRED\r\n*1\r\n$5\r\nGREEN\r\n*1\r\n$4\r\nBLUE\r\n")
    
    h.assert_array_eq[String](["RED"],   try parse.next()? else [] end)
    h.assert_array_eq[String](["GREEN"], try parse.next()? else [] end)
