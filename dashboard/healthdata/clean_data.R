library(readxl)
library(tibble)
library(stringr)
# check if all files have the same columns...
## loop 
files <- list.files(path="healthdata/raw", pattern="*.xls", full.names=TRUE, recursive=FALSE)
reference_header <- unlist(read.csv2("healthdata/ref_header.csv", stringsAsFactors = FALSE))

df <- NULL

for (x in 202:length(files)) {
  file_name <- files[x]
  
  print(file_name)
  
  sheets <- excel_sheets(file_name)
  if("Measure Data" %in% sheets) {
    file <- suppressMessages(read_excel(file_name, sheet = "Measure Data", col_names = FALSE))
  } else if("Ranked Measure Data" %in% sheets) {
    file <- suppressMessages(read_excel(file_name, sheet = "Ranked Measure Data", col_names = FALSE))
  } else {
    print(paste("fail", sheets))
  }
  
  previous_col <- ""
  for(column_index in 4:ncol(file)) {
    current_col <- file[1, column_index]
    
    # TODO move renaming to later
    if(is.na(current_col)) {
      
    } else if(current_col == "Preventable hospital stays (Ambulatory Care Sensitive Conditions)") {
      current_col <- "Preventable hospital stays"
    } else if(current_col == "Premature death (Years of Potential Life Lost)") {
      current_col <- "Premature death"
    } else if(current_col == "Some college (post-secondary education)") {
      current_col <- "Some college"
    }  
    file[1, column_index] <- current_col
    
    if(is.na(current_col)) {
      file[1, column_index] <- previous_col
    }
    
    previous_col <- file[1, column_index]
  }
  
  file[1, 1] <- "FIPS"		
  file[1, 2] <- "State"
  file[1, 3] <- "County"
  
  file <- file[, !is.na(unlist(file[1, ]))]
  
  header <- str_c(unlist(file[1, ]), ":", unlist(file[2, ]))
  header[1:3] <- c("FIPS", "State", "County")
  
  header <- header %>% 
    str_replace("Premature death:Deaths", "Premature death:# Deaths") %>% 
    str_replace("Premature death:Years of Potential Life Lost Rate", "Premature death:YPLL Rate") %>% 
    str_replace("Low birthweight:LBW Births", "Low birthweight:# Low Birthweight Births") %>% 
    str_replace("Low birthweight:Live Births", "Low birthweight:# Live births") %>% 
    str_replace("Sexually transmitted infections:Chlamydia Cases", "Sexually transmitted infections:# Chlamydia Cases") %>% 
    str_replace("Primary care physicians:PCP", "Primary care physicians:# PCP") %>% 
    str_replace("Preventable hospital stays:Preventable Hosp. Rate", "Preventable hospital stays:ACSC Rate") %>% 
    str_replace("Primary care physicians:# Primary Care Physicians", "Primary care physicians:# PCP") %>% 
    str_replace("Preventable hospital stays:# Medicare Enrollees", "Preventable hospital stays:# Medicare enrollees") %>%
    str_replace("Violent crime:# Violent Crimes", "Violent crime:# Annual Violent Crimes")%>%
    str_replace("Violent crime:Annual Violent Crimes", "Violent crime:# Annual Violent Crimes") %>%
    str_replace("Air pollution - particulate matter:Average Daily PM2.5", "Air pollution - particulate matter:Average daily PM25") %>%
    str_replace("Drinking water violations:% Pop in Viol", "Drinking water violations:% pop in viol" ) %>%
    str_replace("Driving alone to work:Workers", "Driving alone to work:# Workers")%>% 
    str_replace("Primary care physicians:PCP", "Primary care physicians:# PCP") %>% 
    str_replace("Preventable hospital stays:Medicare enrollees", "Preventable hospital stays:# Medicare enrollees") %>% 
    str_replace("Low birthweight:LBW Births", "Low birthweight:# Low Birthweight Births") %>% 
    str_replace("Low birthweight:Live Births", "Low birthweight:# Live births") %>% 
    str_replace("Sexually transmitted infections:Chlamydia Cases", "Sexually transmitted infections:# Chlamydia Cases") %>% 
    str_replace("Primary care physicians:PCP", "Primary care physicians:# PCP") %>% 
    str_replace("Violent crime:Annual Violent Crimes", "Violent crime:# Annual Violent Crimes") %>% 
    str_replace("Injury deaths:Injury Deaths", "Injury deaths:# Injury Deaths") %>%
    str_replace("Low birthweight:# Live Births", "Low birthweight:# Live births") %>%
    str_replace("Poor or fair health:% Fair or Poor Health", "Poor or fair health:% Fair/Poor") %>%
    str_replace("Poor physical health days:Average Number of Physically Unhealthy Days", "Poor physical health days:Physically Unhealthy Days") %>%
    str_replace("Poor mental health days:Average Number of Mentally Unhealthy Days", "Poor mental health days:Mentally Unhealthy Days") %>%
    str_replace("Adult obesity:% Adults with Obesity", "Adult obesity:% Obese") %>%
    str_replace("Driving alone to work:Workers", "Driving alone to work:# Workers") %>%
    str_replace("Long commute - driving alone:Long Commute - Drives Alone", "Long commute - driving alone:% Long Commute - Drives Alone") %>%
    str_replace("Long commute - driving alone:Workers who Drive Alone", "Long commute - driving alone:# Workers who Drive Alone") %>%
    str_replace("Severe housing problems:# Household with Severe Problems" , "Severe housing problems:# Households with Severe Problems" )
    
    
    
  #trim empty lines
  file <- file[!is.na(file[,1]),]
  
  # remove header lines
  file <- file[-c(1:2), ]
  
  
  names(file) <- header
  
  if(!all(reference_header %in% header)) {
    print("fail")
  } else {
    file <- file %>% select(all_of(reference_header))
    
    year <- substr(file_name, 10, 13)
    file <- add_column(file, year = year, .before = 1)
    
    
    file[,5:dim(file)[2]] <- sapply(file[,5:dim(file)[2]], as.numeric)
    file[,5:dim(file)[2]] <- sapply(file[,5:dim(file)[2]], round, digits = 2)
  }
  
  
  #save_path <- paste0("healthdata/clean/", file[2,1], file[2,3], ".csv")
  #write.csv2(file, save_path, row.names = FALSE)
  
  df <- rbind(df, file)
}
df[,5:dim(df)[2]] <- sapply(df[,5:dim(df)[2]], as.numeric)

reference_header[1:3] <- c("FIPS", "State", "NAME_2")
names(df) <- c("year", reference_header)

df <- df %>% rename("YPLL Rate" = "Premature death:YPLL Rate", 
                    "YPLL Rate-CIL" = "Premature death:95% CI - Low", 
                    "YPLL Rate-CIH" = "Premature death:95% CI - High", 
                    "YPLL Rate-Z" = "Premature death:Z-Score", 
                    
        "Poor or fair health [in %]" = "Poor or fair health:% Fair/Poor",
        "Poor or fair health [in %]-CIL" = "Poor or fair health:95% CI - Low",
        "Poor or fair health [in %]-CIH" = "Poor or fair health:95% CI - High",
        "Poor or fair health [in %]-Z" = "Poor or fair health:Z-Score",
        
        "Physically Unhealthy Days" = "Poor physical health days:Physically Unhealthy Days",
        "Physically Unhealthy Days-CIL" = "Poor physical health days:95% CI - Low", 
        "Physically Unhealthy Days-CIH" = "Poor physical health days:95% CI - High", 
        "Physically Unhealthy Days-Z" = "Poor physical health days:Z-Score", 
        
        "Mentally Unhealthy Days" = "Poor mental health days:Mentally Unhealthy Days", 
        "Mentally Unhealthy Days-CIL" = "Poor mental health days:95% CI - Low",
        "Mentally Unhealthy Days-CIH" = "Poor mental health days:95% CI - High",
        "Mentally Unhealthy Days-Z" = "Poor mental health days:Z-Score",
        
        "Adult smoking [in %]" = "Adult smoking:% Smokers", 
        "Adult smoking [in %]-CIL" = "Adult smoking:95% CI - Low", 
        "Adult smoking [in %]-CIH" = "Adult smoking:95% CI - High", 
        "Adult smoking [in %]-Z" = "Adult smoking:Z-Score", 
        
        "Adult obesity [in %]" = "Adult obesity:% Obese",
        "Adult obesity [in %]-CIL" = "Adult obesity:95% CI - Low",
        "Adult obesity [in %]-CIH" = "Adult obesity:95% CI - High",
        "Adult obesity [in %]-Z" = "Adult obesity:Z-Score")

df <- df %>% left_join(us_election_states %>% select(State, ST))
df <- df %>% relocate(ST, .before = NAME_2)
write.csv2(df, "healthdata/clean/all.csv", row.names = FALSE)

states <- df %>% filter(is.na(NAME_2))
write.csv2(states, "healthdata/clean/us_health_states.csv", row.names = FALSE)

counties <- df %>% filter(!is.na(NAME_2))
write.csv2(counties, "healthdata/clean/us_health_counties.csv", row.names = FALSE)
