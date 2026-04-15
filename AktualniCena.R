library(quantmod)
library(httr)
library(jsonlite)

# api_key <- Sys.getenv("TWELVE_DATA_API_KEY")
api_key <- "0cdfd49e58824502b938e045552a5ddc"
if (!nzchar(api_key)) {
  stop("Chybí TWELVE_DATA_API_KEY.")
}

# --------------------------------
# puvodni akcie
# --------------------------------
stock_tickers <- c(
  "ABBV","ADM","RIO","AES","AMCR","KO","CVS","DVN",
  "DX","BEN","MBG.DE","OMV.VI","PK","PFE","O","SVC",
  "TGT","VZ","VOW3.DE","BNP.PA","0291.HK","CSG.AS","PEN.PR"
)

# --------------------------------
# ETF doplnene podle ISIN
# interní klice ponechane jednoduche a stabilni
# --------------------------------
etf_tickers <- c(
  "VUAG",   # Vanguard S&P 500 UCITS ETF (USD) Acc
  "EEWD",   # iShares MSCI World ESG Enhanced CTB
  "IWDE",   # iShares MSCI World EUR Hedged
  "EDG2",   # iShares MSCI EM ESG Enhanced
  "IGLO",   # iShares Global Govt Bond
  "HYLE",   # iShares Global High Yield Corp Bond
  "CORP",   # iShares Global Corp Bond
  "EMES",   # iShares JP Morgan ESG USD EM Bond
  "IUKD",   # iShares UK Dividend
  "SPYW",   # SPDR S&P EURO Dividend Aristocrats
  "ZPRG",   # SPDR S&P Global Dividend Aristocrats
  "EQDS",   # iShares MSCI Europe Quality Dividend Advanced
  "ISPA"    # iShares STOXX Global Select Dividend 100 DE
)

# --------------------------------
# celkovy seznam
# --------------------------------
tickers <- c(stock_tickers, etf_tickers)

# --------------------------------
# nazvy
# --------------------------------
name_map <- c(
  # akcie
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
  "PEN.PR"  = "Photon Energy",
  
  # ETF
  "VUAG"    = "Vanguard S&P 500 UCITS ETF (USD) Acc",
  "EEWD"    = "iShares MSCI World ESG Enhanced CTB",
  "IWDE"    = "iShares MSCI World EUR Hedged",
  "EDG2"    = "iShares MSCI EM ESG Enhanced",
  "IGLO"    = "iShares Global Govt Bond",
  "HYLE"    = "iShares Global High Yield Corp Bond",
  "CORP"    = "iShares Global Corp Bond",
  "EMES"    = "iShares JP Morgan ESG USD EM Bond",
  "IUKD"    = "iShares UK Dividend",
  "SPYW"    = "SPDR S&P EURO Dividend Aristocrats",
  "ZPRG"    = "SPDR S&P Global Dividend Aristocrats",
  "EQDS"    = "iShares MSCI Europe Quality Dividend Advanced",
  "ISPA"    = "iShares STOXX Global Select Dividend 100 DE"
)

# --------------------------------
# ISIN map - doplneno hlavne pro ETF
# --------------------------------
isin_map <- c(
  # akcie - zde neni ISIN doplnen
  "ABBV"    = NA,
  "ADM"     = NA,
  "RIO"     = NA,
  "AES"     = NA,
  "AMCR"    = NA,
  "KO"      = NA,
  "CVS"     = NA,
  "DVN"     = NA,
  "DX"      = NA,
  "BEN"     = NA,
  "MBG.DE"  = NA,
  "OMV.VI"  = NA,
  "PK"      = NA,
  "PFE"     = NA,
  "O"       = NA,
  "SVC"     = NA,
  "TGT"     = NA,
  "VZ"      = NA,
  "VOW3.DE" = NA,
  "BNP.PA"  = NA,
  "0291.HK" = NA,
  "CSG.AS"  = NA,
  "PEN.PR"  = NA,
  
  # ETF
  "VUAG" = "IE00BFMXXD54",
  "EEWD" = "IE00BG11HV38",
  "IWDE" = "IE00B441G979",
  "EDG2" = "IE00BHZPJ239",
  "IGLO" = "IE00BKT6FT27",
  "HYLE" = "IE00BJSFR200",
  "CORP" = "IE00BJSFQW37",
  "EMES" = "IE00BKP5L730",
  "IUKD" = "IE00B0M63060",
  "SPYW" = "IE00B5M1WJ87",
  "ZPRG" = "IE00B9CQXS71",
  "EQDS" = "IE00BYYHSM20",
  "ISPA" = "DE000A0F5UH1"
)

# --------------------------------
# mapa men
# mena odpovida sledovanemu listingu / kotaci
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
  "PEN.PR"  = "CZK",
  
  "VUAG"    = "GBP",
  "EEWD"    = "USD",
  "IWDE"    = "EUR",
  "EDG2"    = "USD",
  "IGLO"    = "USD",
  "HYLE"    = "EUR",
  "CORP"    = "USD",
  "EMES"    = "USD",
  "IUKD"    = "GBP",
  "SPYW"    = "EUR",
  "ZPRG"    = "USD",
  "EQDS"    = "EUR",
  "ISPA"    = "EUR"
)

# --------------------------------
# symboly pro Twelve Data
# u ETF se zkusi primarni ticker bez suffixu
# kdyz neprojde, fallbackne to na Yahoo
# --------------------------------
td_symbol_map <- c(
  "ABBV"    = "ABBV",
  "ADM"     = "ADM.L",
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
  "PEN.PR"  = "PEN.PR",
  
  "VUAG"    = "VUAG",
  "EEWD"    = "EEWD",
  "IWDE"    = "IWDE",
  "EDG2"    = "EDG2",
  "IGLO"    = "IGLO",
  "HYLE"    = "HYLE",
  "CORP"    = "CORP",
  "EMES"    = "EMES",
  "IUKD"    = "IUKD",
  "SPYW"    = "SPYW",
  "ZPRG"    = "ZPRG",
  "EQDS"    = "EQDS",
  "ISPA"    = "ISPA"
)

# --------------------------------
# symboly pro Yahoo
# zde je dulezity spravny burzovni suffix
# --------------------------------
yahoo_symbol_map <- c(
  "ABBV"    = "ABBV",
  "ADM"     = "ADM.L",
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
  "PEN.PR"  = "PEN.PR",
  
  "VUAG"    = "VUAG.L",
  "EEWD"    = "EEWD.L",
  "IWDE"    = "IWDE.L",
  "EDG2"    = "EDG2.L",
  "IGLO"    = "IGLO.L",
  "HYLE"    = "HYLE.L",
  "CORP"    = "CORP.L",
  "EMES"    = "EMES.L",
  "IUKD"    = "IUKD.L",
  "SPYW"    = "SPYW.DE",
  "ZPRG"    = "ZPRG.L",
  "EQDS"    = "EQDS.L",
  "ISPA"    = "ISPA.DE"
)

# --------------------------------
# prevod ceny do cilove meny
# ADM na LSE je v GBp/GBX -> GBP
# --------------------------------
price_multiplier_map <- c(
  "ADM" = 0.01
)

convert_price <- function(ticker, price_value) {
  mult <- if (ticker %in% names(price_multiplier_map)) {
    unname(price_multiplier_map[[ticker]])
  } else {
    1
  }
  
  round(price_value * mult, 4)
}

# --------------------------------
# pomocna funkce - bezpecne cteni z mapy
# --------------------------------
map_value <- function(map_obj, key, default = NA_character_) {
  if (key %in% names(map_obj)) {
    unname(map_obj[[key]])
  } else {
    default
  }
}

# --------------------------------
# 1) snapshot pres Twelve Data /price
#    fallback na Yahoo daily close
# --------------------------------
get_snapshot_row <- function(t) {
  
  isin_val     <- map_value(isin_map, t)
  name_val     <- map_value(name_map, t)
  currency_val <- map_value(currency_map, t)
  td_symbol    <- map_value(td_symbol_map, t, t)
  yahoo_symbol <- map_value(yahoo_symbol_map, t, t)
  
  tryCatch({
    
    price_val  <- NA_real_
    time_val   <- NA_character_
    source_val <- NA_character_
    
    # --- pokus pres Twelve Data ---
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
        raw_price <- as.numeric(json$price)
        price_val <- convert_price(t, raw_price)
        
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
        Symbols = yahoo_symbol,
        src = "yahoo",
        auto.assign = FALSE
      ))
      
      raw_price <- as.numeric(last(Cl(data_d)))
      price_val <- convert_price(t, raw_price)
      
      dt_val <- as.Date(index(last(data_d)))
      time_val <- paste0(format(dt_val, "%d.%m.%Y"), " close")
      source_val <- "yahoo_fallback"
    }
    
    data.frame(
      ticker = t,
      isin = isin_val,
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
      isin = isin_val,
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

write.csv(
  snapshot_result,
  "stocks.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# --------------------------------
# 2) denni close za poslednich 30 obchodnich dnu z Yahoo
# --------------------------------
get_history_rows <- function(t) {
  
  isin_val     <- map_value(isin_map, t)
  currency_val <- map_value(currency_map, t)
  name_val     <- map_value(name_map, t)
  yahoo_symbol <- map_value(yahoo_symbol_map, t, t)
  
  tryCatch({
    
    data <- suppressWarnings(getSymbols(
      Symbols = yahoo_symbol,
      src = "yahoo",
      from = Sys.Date() - 45,
      to   = Sys.Date(),
      auto.assign = FALSE
    ))
    
    close_vals <- round(
      vapply(
        as.numeric(Cl(data)),
        function(x) convert_price(t, x),
        numeric(1)
      ),
      4
    )
    
    df <- data.frame(
      date = format(index(data), "%d.%m.%Y"),
      ticker = t,
      isin = isin_val,
      name = name_val,
      close = close_vals,
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
      isin = isin_val,
      name = name_val,
      close = NA_real_,
      currency = currency_val,
      stringsAsFactors = FALSE
    )
  })
}

history_list <- lapply(tickers, get_history_rows)
history_result <- do.call(rbind, history_list)

write.csv(
  history_result,
  "stocks_history_30d.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

print(snapshot_result)
print("Data ulozena do stocks.csv")
print("Historie ulozena do stocks_history_30d.csv")
