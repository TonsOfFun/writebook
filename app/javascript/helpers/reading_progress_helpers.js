import { setCookie, readCookie } from "helpers/cookie_helpers"

export function getReadingProgress(bookId) {
  const progress = readCookie(`reading_progress_${bookId}`)

  if (progress) {
    const [ leafId, lastReadParagraph ] = progress.split("/")
    return [ parseInt(leafId), parseInt(lastReadParagraph) || 0 ]
  } else {
    return [ undefined, 0 ]
  }
}

export function storeReadingProgress(bookId, leafId, lastReadParagraphIndex) {
  setCookie(`reading_progress_${bookId}`, `${leafId}/${lastReadParagraphIndex}`)
}
