#' Zipf law
displex_zipf_law <- function(w, k=1,a=1,d=0) {
  f = k/(seq_along(w)+d)^a
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

# General function for obtaining the spectrum of a interest center
# data   -> data.frame as provided by read.displex
# law    -> law to quantify compatibility with interest center
# reduce -> law to reduce the valorations of each word in each center to just one number
# return a data.frame with the field availability added.
displex_availability <- function(data,law=displex_exp_law, reduce=displex_additive_law) {
  words        = character()
  availability = numeric()

  for (i in seq_along(data$words)) {
    words        = c(words, data$words[i][[1]])
    availability =c(availability, law(data$words[i][[1]]))
  }
  centers     = rep(data$centers, vapply(data$words, FUN = function(x) length(x), FUN.VALUE = 0L))
  data.frame(centers=centers, words=words, availability=availability) %>%
    group_by(centers,words) %>%
    summarise(availability=reduce(availability)) %>%
    ungroup()
}

# Obtain the availability following the López-Strassburger model
# return a data.frame with the field availability added.
displex_lopezstrass_availability <- function(data) {
  # Máxima posición alcanzada
  n <- max(vapply(data$words, function(x) {length(x)}, FUN.VALUE=1L))
  # Número total de hablantes
  N <- length(unique(data$users))

  displex_availability(data   = data,
                       law    = function(w) {displex_exp_law(w,a=exp(2.3/(n-1)),d=-1)},
                       reduce = function(x) {sum(x) / N})
}

# Obtain the availability following the Ávila-Sánchez model
# returns a data.frame with the field availability added.
displex_avilasanchez_availability <- function(data, k=1) {
  displex_availability(d,
                       law=function(x) {displex_zipf_law(x,k=k,d=1)},
                       reduce=displex_additive_law)
}

# Sugeno integral of the fuzzy set d, respect fuzzy measure g
# Returns the value of the integral

fuzzy.expected.value <- function(d, g=function(x) {length(x)/length(d)}) {
  # Calculate by function, and the levels for alpha
  levels <- sort(unique(d), decreasing=TRUE)
  # Determine alpha cuts and its measure
  gs <- sapply(levels,function(x) {g(d[d >= x])})
  res  <- cbind(levels,gs)
  res <- max(apply(res,1,min))
  res
}

