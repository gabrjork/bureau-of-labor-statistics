# Puxando dados divulgados pelo BLS
library(tidyverse)
library(dplyr)
library(blsR)
library(beepr)
library(zoo)
library(writexl)

# Define the working directory
choose.files() # only to prompt the graphics to choose.dir()
diretorio <- choose.dir()
setwd(diretorio)
getwd()

# Set your BLS API key if you have one (optional)
bls_set_key("insert your key in here")
bls_has_key()

# Define BLS series IDs for key labor market indicators
series_ids <- c(
    "CES0000000001", # Total Nonfarm Payroll Employment
    "LNS12000000", # Employed Persons
    "LNS13000000", # Unemployed Persons
    "LNS11000000", # Civilian Labor Force Level
    "CES0500000003" # Average Hourly Earnings
)

names(series_ids) <- c(
    "PAYROLLtotal",
    "EMPPOP",
    "UNEMPPOP",
    "LABORFORCE",
    "AVGHOURSEARNINGS"
)

chamada <- query_n_series(
    series_ids = series_ids,
    start_year = 2024,
    end_year = 2025,
    catalog = FALSE,
    calculations = FALSE,
    annualaverage = FALSE,
)

# Retrieve the latest 12 months of data for each series
labor_data <- bls_request(chamada)

View(labor_data)
class(labor_data)


# Converte lista da API em data frame plano
labor_df <- map_dfr(
    labor_data$series,
    ~ {
        df <- bind_rows(.x$data) # trata a lista corretamente como data.frame
        df$seriesID <- .x$seriesID
        df
    }
)

# Cria tabela com nomes dos indicadores
series_names <- tibble(
    seriesID = unname(series_ids),
    indicator = names(series_ids)
)

labor_df <- labor_df %>%
    left_join(series_names, by = "seriesID") %>%
    mutate(
        value = as.numeric(value),
        year = as.integer(year),
        period_num = str_remove(period, "M") %>% as.integer(),
        date = format(zoo::as.yearmon(paste(year, period_num), "%Y %m"), "%Y-%m")
    ) %>%
    select(seriesID, indicator, year, period = period_num, date, value)

labor_df <- labor_df %>%
    select(-seriesID, -year, -period) %>%
    pivot_wider(
        names_from = indicator,
        values_from = value
    ) %>%
    arrange(date)

labor_df <- mutate(labor_df,
    PAYROLL = PAYROLLtotal - lag(PAYROLLtotal, 1)
)

labor_df <- mutate(labor_df,
    UNEMPRATE = UNEMPPOP / LABORFORCE * 100
)

View(labor_df)

# Save the data frame to an Excel file
timestamp <- format(Sys.time(), "%Y-%m")
nome_arquivo <- paste0("Mercado_de_Trabalho_BLS_", timestamp, ".xlsx")
write_xlsx(labor_df, nome_arquivo, col_names = TRUE)

# Play a sound to indicate completion
beep(2)
