
source("config.ini")

install.packages(c("httr", "jsonlite", "lubridate", "plyr"))

library(httr)
library(jsonlite)
library(plyr)

# row bind data with missing cells
rbind_apicall <- function(apicall) {
    apicall_df_singlepage <- rbind.fill(lapply(content(apicall)$results, 
        function(f) { as.data.frame(Filter(Negate(is.null), f)) } ))
    return(apicall_df_singlepage)
}

# returns dataframe from an API call, stitching together results from all pages
api_to_df <- function(url, username, password){
    apicall_data <- GET(url, authenticate(username,password))
    apicall_data_df <- rbind_apicall(apicall_data)
    apicall_data_content <- content(apicall_data)
    num_pages <- ceiling(apicall_data_content$count/10)
    progress_bar = txtProgressBar(min = 1, max = num_pages-1, initial = 0, style=3) 

    for (i in 2:num_pages) {
        setTxtProgressBar(progress_bar,i)
        apicall_data_next <- GET(paste(url, paste("page=", i,sep=""),sep="&"), 
                                 authenticate(username,password))
        apicall_data_df_next <- rbind_apicall(apicall_data_next)
        apicall_data_df <- rbind.fill(apicall_data_df, apicall_data_df_next)                            
    }
    return(apicall_data_df)
}

mpa_url <- "http://afsisdb.qed.ai/cabinet/api/sample/?machine=mpa"
mpa_df <- api_to_df(mpa_url, username, password)

str(mpa_df)

TanSIS_mpa_url <- "http://afsisdb.qed.ai/cabinet/api/sample/?group=TanSIS&machine=mpa"
TanSIS_mpa_df <- api_to_df(TanSIS_mpa_url, username, password)

str(TanSIS_mpa_df)

progress_bar = txtProgressBar(min = 1, max = 10, initial = 0, style=3) 
setTxtProgressBar(progress_bar,0)
for (i in 1:10) {
    file_name = paste(as.character(mpa_df$ssn[i]), 
                      as.character(mpa_df$subsample_id[i]), sep=".")
    download.file(as.character(mpa_df$binary_file[i]), method="curl", destfile=file_name) 
    setTxtProgressBar(progress_bar,i)
}

wetchem_1af_url <- "https://afsisdb.qed.ai/cabinet/api/wetchemistry/?group=1AF"

wetchem_1af_data <- api_to_df(wetchem_1af_url, username, password)

str(wetchem_1af_data)
