#' Zipf law
displex_zipf_law <- function(w, k=1,a=1,d=0) {
  f = 1/(seq_along(w)+d)^a
  names(f) <- w
  f
}

#' Exponential law
displex_exp_law <- function(w,a=2,k=1,d=0) {
  f = k/a^(seq_along(w)+d)
  names(f) <- w
  f
}


#' Additive reduce law
displex_additive_law <- function(w,k=1) {
  1 - prod(1-w)^k
}

#' Read displex file
#'
#' This function reads file in the expected format from displex
#' @param file File name of the file with the data
#' @keywords read, displex
read.displex <- function(file) {
  f = readLines(file)
  infos   = character()
  users   = character()
  centers = character()
  words   = list()

  for (i in seq_along(f)) {
    a <- str_match(f[i], "^(\\d+) (\\d+) (\\d+) (.+)$")[-1]
    infos[length(infos)+1] = a[1]
    users[length(users)+1] = a[2]
    centers[length(centers)+1] = a[3]
    w = strsplit(a[4], ",")[[1]]
    for (i in seq_along(w)) {
      w[i] = trimws(w[i])
    }
    #w$class = "displex_wordlist"
    words[[length(words)+1]] = w
  }
  d <- data.frame(infos=infos, users=users, centers=centers, words=I(words))
  d
}

displex_availability <- function(data,law=displex_exp_law, reduce=displex_additive_law) {
  words        = character()
  availability = numeric()

  for (i in seq_along(data$words)) {
    words        = c(words, data$words[i][[1]])
    availability =c(availability, law(data$words[i][[1]]))
  }
  centers     = rep(data$centers, vapply(data$words, FUN = function(x) length(x), FUN.VALUE = 0L))
  d <- data.frame(centers=centers, words=words, availability=availability)
  d %>% group_by(centers,words) %>% summarise(availability=reduce(availability)) %>% ungroup()
}


sugeno.integral <- function(d, g=function(x) {length(x)/length(d)}, h=function(x) {x}) {
  # Calculate by function, and the levels for alpha
  vals <- h(d)
  levels <- sort(unique(vals), decreasing=TRUE)
  # Determine alpha cuts and its measure
  gs <- sapply(levels,function(x) {g(d[vals >= x])})
  res  <- cbind(levels,gs)
  res <- max(apply(res,1,min))
  res
}

