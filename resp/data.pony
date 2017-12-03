type Data   is (None | OK | Error | String | I64 | ElementsAny)
type _Token is (None | OK | Error | String | I64 | USize)

primitive OK
  fun string(): String => "OK"

class val Error
  let message: String
  new val create(message': String) => message = message'
  fun string(): String => "Error(" + message + ")"

trait val ElementsAny
  fun string(): String
  fun size(): USize
  fun apply(i: USize): Data?
  fun values(): Iterator[Data]

class val Elements[A: Data = Data] is ElementsAny
  embed array: Array[A] = array.create()
  fun ref push(elem: A) => array.push(elem)
  fun size(): USize => array.size()
  fun apply(i: USize): A? => array(i)?
  fun values(): Iterator[A] => array.values()
  fun string(): String =>
    let buf = recover String end
    buf.push('[')
    for (idx, elem) in array.pairs() do
      if idx > 0 then buf.>push(';').push(' ') end
      buf.append(elem.string())
    end
    buf.push(']')
    buf
