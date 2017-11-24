use "ponytest"
use ".."

class TestRespond is UnitTest
  fun name(): String => "resp.Respond"
  
  fun apply(h: TestHelper) =>
    Respond(h.env.out)
