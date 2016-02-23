#' Extract a table from a Word document
#'
#' Given a document read with \code{read_docx} and a table to extract (optionally
#' indicating whether there was a header or not and if cell whitepace trimming is
#' desired) extract the contents of the table to a \code{data.frame}.
#'
#' @param docx \code{docx} object read with \code{read_docx}
#' @param tbl_number which table to extract (defaults to \code{1})
#' @param header assume first row of table is a header row? (default; \code{TRUE})
#' @param trim trim leading/trailing whitespace (if any) in cells? (default: \code{TRUE})
#' @return \code{data.frame}
#' @seealso \code{\link{docx_extract_all}}, \code{\link{docx_extract_tbl}},
#'          \code{\link{assign_colnames}}
#' @export
#' @examples
#' doc3 <- read_docx(system.file("examples/data3.docx", package="docxtractr"))
#' docx_extract_tbl(doc3, 3)
docx_extract_tbl <- function(docx, tbl_number=1, header=TRUE, trim=TRUE) {

  ensure_docx(docx)
  if ((tbl_number < 1) | (tbl_number > docx_tbl_count(docx))) {
    stop("'tbl_number' is invalid.", call.=FALSE)
  }

  ns <- docx$ns
  tbl <- docx$tbls[[tbl_number]]

  cells <- xml_find_all(tbl, "./w:tr/w:tc", ns=ns)
  rows <- xml_find_all(tbl, "./w:tr", ns=ns)

 # bind_rows(lapply(rows, function(row) {
#
 #   vals <- xml_text(xml_find_all(row, "./w:tc", ns=ns), trim=trim)
  #  names(vals) <- sprintf("V%d", 1:length(vals))
   # data.frame(as.list(vals), stringsAsFactors=FALSE)
#
 # })) -> dat
 
  bind_rows(lapply(rows, function(row) {
    vals <- xml_text(xml_find_all(row, "./w:tc", ns=ns), trim=FALSE)
    names(vals) <- sprintf("V%d", 1:length(vals))
    vals <- as.list(vals)
    #redo column 5 to get formatting
    columns <-  xml_find_all(row, "./w:tc", ns=ns)
    paragraphs <-  xml_find_all(columns[5], "./w:p", ns=ns) 
    
    textout <-""
    
    #loop through the paragraphs
    for(i in 1:length(paragraphs)){
      #is it a bullet point?
      if(grepl("<w:numPr>", as.character(paragraphs[i])))  textout<- paste(textout,"* ", as.character(xml_text(paragraphs[i])), sep="")
      #is it bold
      else if(grepl("w:b/", as.character(paragraphs[i]))) textout<- paste(textout,"**", as.character(xml_text(paragraphs[i])),"**", sep="")
      else textout<- paste(textout, as.character(xml_text(paragraphs[i])), sep="")
      textout <- iconv(textout, "", "ASCII", "byte")
    textout <-gsub("<e2><80><99>", "'", textout)
        textout <-gsub("<c2><a0>", "  \n", textout)
    }
    vals[5] <- textout
   data.frame(vals, stringsAsFactors=FALSE)
   
  })) -> dat
  
  if (header) {
    colnames(dat) <- dat[1,]
    dat <- dat[-1,]
  } else {
    hdr <- has_header(tbl, rows, ns)
    if (!is.na(hdr)) {
      message("NOTE: header=FALSE but table has a marked header row in the Word document")
    }
  }

  rownames(dat) <- NULL

  dat

}

#' Get number of tables in a Word document
#'
#' @param docx \code{docx} object read with \code{read_docx}
#' @return numeric
#' @export
#' @examples
#' complx <- read_docx(system.file("examples/complex.docx", package="docxtractr"))
#' docx_tbl_count(complx)
docx_tbl_count <- function(docx) {
  ensure_docx(docx)
  length(docx$tbls)
}
