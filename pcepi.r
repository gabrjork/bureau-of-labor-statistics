#### ==== Puxando a tabela 2.8.4 do PCEPI pela API do BEA ==== ####

library(dplyr)
library(tidyr)
library(devtools)
library(httr)
library(eu.us.opendata)
library(jsonlite)
library(writexl)

# Substitua 'YOUR_USER_ID' pelo seu UserID real da API do BEA
api_key <- ""

# 2. Defina a URL base da API e os parâmetros
base_url <- "https://apps.bea.gov/api/data"
params <- list(
  UserID = api_key,
  Method = "GetData",
  datasetname = "NIPA",
  TableName = "T20804",     # Tabela 2.8.4.
  Frequency = "M",          # Mensal
  Year = "2024, 2025",             # Todos os anos disponíveis
  ResultFormat = "JSON"
)

# 3. Requisição à API
response <- GET(base_url, query = params)
stop_for_status(response)

# 4. Processar o JSON
content_json <- content(response, as = "text", encoding = "UTF-8")
data_list <- fromJSON(content_json, flatten = TRUE)

# 5. Extrair os dados
df <- data_list$BEAAPI$Results$Data

# 6. Converter DataValue para numérico
df$DataValue <- as.numeric(gsub(",", "", df$DataValue))

# 7. Pivotar para formato wide (transposta)
df_wide <- df %>%
  select(LineDescription, TimePeriod, DataValue) %>%
  pivot_wider(names_from = TimePeriod, values_from = DataValue)


# 8. Salvando com timestamp
timestamp <- format(Sys.time(), "%Y%m%d")
nome <- paste0("PCE", timestamp, ".xlsx")

write_xlsx(df_wide, nome)

