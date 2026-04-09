library(quantmod)
library(httr)
library(jsonlite)

# --------------------------------
# Twelve Data API key
# --------------------------------
api_key <- "0cdfd49e58824502b938e045552a5ddc"

# --------------------------------
# tickery v požadovaném pořadí
# --------------------------------
tickers <- c("ABBV","ADM","RIO","AES","AMCR","KO","CVS","DVN",
             "DX","BEN","MBG.DE","OMV.VI","PK","PFE","O","SVC",
             "TGT","VZ","VOW3.DE","BNP.PA","0291.HK","CSG.AS","PEN.PR")

# --------------------------------
# názvy akcií
# --------------------------------
name_map <- c(
  "ABBV"    = "AbbVie",
  "ADM"     = "Admiral Group PLC",
  "RIO"     = "ADR on Rio Tinto",
  "AES"     = "AES Corp",
  "AMCR"    = "Amcor",
  "KO"      = "Coca-Cola",
  "CVS"     = "CVS Health",
  "DVN"     = "Devon Energy",
  "DX"      = "Dynex Capital Inc",
  "BEN"     = "Franklin Resources",
  "MBG.DE"  = "Mercedes-Benz Group",
  "OMV.VI"  = "OMV",
  "PK"      = "Park Hotels & Resorts Inc",
  "PFE"     = "Pfizer",
  "O"       = "Realty Income",
  "SVC"     = "Service Properties Trust",
  "TGT"     = "Target Corp",
  "VZ"      = "Verizon",
  "VOW3.DE" = "Volkswagen AG",
  "BNP.PA"  = "BNP Paribas SA",
  "0291.HK" = "China Resources Beer",
  "CSG.AS"  = "CSG N.V.",
  "PEN.PR"  = "Photon Energy"
)

# --------------------------------
# mapa měn
# --------------------------------
currency_map <- c(
  "ABBV"    = "USD",
  "ADM"     = "GBP",
  "RIO"     = "USD",
  "AES"     = "USD",
  "AMCR"    = "USD",
  "KO"      = "USD",
  "CVS"     = "USD",
  "DVN"     = "USD",
  "DX"      = "USD",
  "BEN"     = "USD",
  "MBG.DE"  = "EUR",
  "OMV.VI"  = "EUR",
  "PK"      = "USD",
  "PFE"     = "USD",
  "O"       = "USD",
  "SVC"     = "USD",
  "TGT"     = "USD",
  "VZ"      = "USD",
  "VOW3.DE" = "EUR",
  "BNP.PA"  = "EUR",
  "0291.HK" = "HKD",
  "CSG.AS"  = "EUR",
  "PEN.PR"  = "CZK"
)

# --------------------------------
# mapování symbolů pro Twelve Data
# --------------------------------
td_symbol_map <- c(
  "ABBV"    = "ABBV",
  "ADM"     = "ADM",
  "RIO"     = "RIO",
  "AES"     = "AES",
  "AMCR"    = "AMCR",
  "KO"      = "KO",
  "CVS"     = "CVS",
  "DVN"     = "DVN",
  "DX"      = "DX",
  "BEN"     = "BEN",
  "MBG.DE"  = "MBG.DE",
  "OMV.VI"  = "OMV.VI",
  "PK"      = "PK",
  "PFE"     = "PFE",
  "O"       = "O",
  "SVC"     = "SVC",
  "TGT"     = "TGT",
  "VZ"      = "VZ",
  "VOW3.DE" = "VOW3.DE",
  "BNP.PA"  = "BNP.PA",
  "0291.HK" = "0291.HK",
  "CSG.AS"  = "CSG.AS",
  "PEN.PR"  = "PEN.PR"
)

# --------------------------------
# 1) snapshot přes Twelve Data /price
#    fallback na Yahoo daily close
# --------------------------------
get_snapshot_row <- function(t) {
  
  name_val <- if (t %in% names(name_map)) unname(name_map[[t]]) else NA_character_
  currency_val <- if (t %in% names(currency_map)) unname(currency_map[[t]]) else NA_character_
  td_symbol <- if (t %in% names(td_symbol_map)) unname(td_symbol_map[[t]]) else t
  
  tryCatch({
    
    price_val <- NA_real_
    time_val <- NA_character_
    source_val <- NA_character_
    
    # --- pokus přes Twelve Data ---
    td_ok <- FALSE
    
    try({
      url <- modify_url(
        "https://api.twelvedata.com/price",
        query = list(
          symbol = td_symbol,
          apikey = api_key
        )
      )
      
      res <- GET(url)
      txt <- content(res, as = "text", encoding = "UTF-8")
      json <- fromJSON(txt)
      
      if (!is.null(json$status) && identical(json$status, "error")) {
        stop(if (!is.null(json$message)) json$message else "Twelve Data error")
      }
      
      if (!is.null(json$price) && nzchar(json$price)) {
        price_val <- round(as.numeric(json$price), 4)
        
        ts_val <- as.POSIXct(
          round(as.numeric(Sys.time()) / 60) * 60,
          origin = "1970-01-01",
          tz = "Europe/Prague"
        )
        time_val <- format(ts_val, "%d.%m.%Y %H:%M")
        source_val <- "twelve_data_price"
        td_ok <- TRUE
      }
    }, silent = TRUE)
    
    # --- fallback na Yahoo daily close ---
    if (!td_ok) {
      data_d <- suppressWarnings(getSymbols(
        Symbols = t,
        src = "yahoo",
        auto.assign = FALSE
      ))
      
      price_val <- round(as.numeric(last(Cl(data_d))), 4)
      dt_val <- as.Date(index(last(data_d)))
      time_val <- paste0(format(dt_val, "%d.%m.%Y"), " close")
      source_val <- "yahoo_fallback"
    }
    
    data.frame(
      ticker = t,
      name = name_val,
      price = price_val,
      currency = currency_val,
      time = time_val,
      source = source_val,
      stringsAsFactors = FALSE
    )
    
  }, error = function(e) {
    
    data.frame(
      ticker = t,
      name = name_val,
      price = NA_real_,
      currency = currency_val,
      time = NA_character_,
      source = "snapshot_error",
      stringsAsFactors = FALSE
    )
  })
}

snapshot_list <- lapply(tickers, get_snapshot_row)
snapshot_result <- do.call(rbind, snapshot_list)

write.csv(snapshot_result, "D:/R/Akcie/stocks.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

# --------------------------------
# 2) denní close za posledních 30 obchodních dnů z Yahoo
# --------------------------------
get_history_rows <- function(t) {
  
  currency_val <- if (t %in% names(currency_map)) {
    unname(currency_map[[t]])
  } else {
    NA_character_
  }
  
  name_val <- if (t %in% names(name_map)) {
    unname(name_map[[t]])
  } else {
    NA_character_
  }
  
  tryCatch({
    
    data <- suppressWarnings(getSymbols(
      Symbols = t,
      src = "yahoo",
      from = Sys.Date() - 45,
      to   = Sys.Date(),
      auto.assign = FALSE
    ))
    
    df <- data.frame(
      date = format(index(data), "%d.%m.%Y"),
      ticker = t,
      name = name_val,
      close = round(as.numeric(Cl(data)), 4),
      currency = currency_val,
      stringsAsFactors = FALSE
    )
    
    if (nrow(df) > 30) {
      df <- tail(df, 30)
    }
    
    df
    
  }, error = function(e) {
    data.frame(
      date = NA_character_,
      ticker = t,
      name = name_val,
      close = NA_real_,
      currency = currency_val,
      stringsAsFactors = FALSE
    )
  })
}

history_list <- lapply(tickers, get_history_rows)
history_result <- do.call(rbind, history_list)

write.csv(history_result, "D:/R/Akcie/stocks_history_30d.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

print(snapshot_result)
print("Data uložena do stocks.csv")
print("Historie uložena do stocks_history_30d.csv")