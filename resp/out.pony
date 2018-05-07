interface tag OutAsync
  be write(data: ByteSeq)
  be writev(data: ByteSeqIter)

interface ref OutSync
  fun ref write(data: ByteSeq)
  fun ref writev(data: ByteSeqIter)
