## config ####

jtds.path <- "" # path to jtds , e.g. ~/jtds-1.3.1.jar
db.connection.string <- "" # string to connect to your database, e.g.
                           # "jdbc:jtds:sybase://10.10.10.10:5000"

db.name <- "" # name of swisslab database, e.g. SWISSLAB
db.user <- "" # your database user name 
db.pass <- "" # your database password

labname <- "" #  your lab ID: at least 6 symbols (letter, number, underscore, point)

mail.from = "" # the adress of your email-server for export, 
               # e.g. 'emailserver@mailAdress.net'
mail.to = "" # the recipient address, will be supplied by Linda Thienpont
             # can also include your private adress 
             # c('your@mailAdress.net', 'percentile@mailAdress.net')
mail.replyTo = "" # in case someting went wrong it a good idea that people
                  # know how to contact you, e.g. your@mailAdress.net
mail.smtphost = "" # your smtp host e.g. smtp.emailserver.nowehere.de

analytes <- c() # analyte codes from swisslab for 
                # Albumin, Alkaline Phosphatase, Alanine aminotransferease (ALT), 
                # Aspartate aminotransferase (AST), total-Bilirubin, Calcium, 
                # total-Cholesterol, Chloride, C-reactive protein (CRP), 
                # Gamma-glutamyltransferase(GGT), Glucose, Potassium, Creatinine, 
                # Lactate dehydrogenase (LDH), Magnesium, 
                # Inorganic phosphor (phosphate), Total-Protein, Sodium, 
                # Urea, Uric acid (urate), FT4, TSH, HDL-Cholesterol, Triglycerides, 
                # Vitamin B12, 25-Hydroxyvitamin D, Folate, Ferritin, 
                # Immunoglobulin A, Immunoglobulin G, Immunoglobulin M, Hemoglobin, 
                # Glycated hemoglobin, Mean Corposcular Volume, Mean Platelet Volume, 
                # Platelets, Red blood cell count, White blood cell count

                #  e.g. c("ALB", "AP", "GPT", "GOT", ...)
  
date.offset <- 3 # The script uses not today's measurements but measurements from X days
                 # ago to ensure everything is final. 

## load packages ####
# make sure these are installed...

library(tidyverse)
library(magrittr)
library(lubridate)
library(RJDBC)
library(sendmailR)


## extract data ####
drv <- JDBC('net.sourceforge.jtds.jdbc.Driver',  jtds.path)

conn <- dbConnect(drv, db.connection.string, 
                  user = db.user, password = db.pass, dbname = db.name )

anaDate <- lubridate::today() - date.offset

dateBis <- strftime(anaDate, "%d.%m.%Y 00:00:00:000")
dateVon <- strftime(anaDate -7, "%d.%m.%Y 00:00:00:000")

geraete <- RJDBC::dbGetQuery(conn, "select * from GERAET") 
analyte <- RJDBC::dbGetQuery(conn, paste0("select A.ANALYTX, U.UNIT ",
                                          "from ANALYT A ",
                                          "join UNITANALYTREF UA ",
                                          "on UA.ANALYTX = A.ANALYTX ",
                                          "join UNIT U ",
                                          "on U.UNITX = UA.UNITX ",
                                          "where UA.STORNODAT is null"))


output <- purrr::map_dfr(analytes, function(a){
  res <- RJDBC::dbGetQuery(conn, 
                           str_interp("exec PR_SUCHEWERTE @CODE1='${a}',
                                    @ART = 'R', @PATIART = 'AM',
                                    @DATUMVON ='${dateVon}',
                                    @DATUMBIS ='${dateBis}'"))
  
  res <- res %>%
    mutate(datum = strftime(lubridate::as_date(FREIGABEDAT1), "%d/%m/%Y")) %>%
    filter(datum == strftime(anaDate, "%d/%m/%Y"))
  
  cat(nrow(res), ' results for ', a, ".\n", sep='')
  if(nrow(res) > 0){
    
    # prevent too long queries
    rx <- unique(res$RESULTATX1)
    rxl <- split(rx, rep_len(1:ceiling(length(rx)/100), length(rx)))
    
    geraete_res <- purrr::map_dfr(rxl, function(r){
      rStr <-paste(r, collapse = ', ', sep = '')
      RJDBC::dbGetQuery(conn, 
                        str_interp("select * from RESULTAT WHERE RESULTATX 
                                        IN (${rStr})"))
    })
    
    o <- res %>%
      filter(!is.na(ERGEBNISF1)) %>%
      left_join(geraete_res, by = c("RESULTATX1" = "RESULTATX")) %>%
      filter(!is.na(GERAETX)) %>%
      left_join(geraete, by = "GERAETX") %>%
      left_join(analyte, by = "ANALYTX") 
    
    o <- o %>%
      group_by(CODE1, GERAETENR, datum) %>%
      summarise(med = median(ERGEBNISF1), n = n(), EINHEIT = UNIT[1]) %>%
      ungroup()
    
    o
  }
  else{
    data.frame()
  }
})

# format mail ####
cat('Writing Email.\n')

output <- output %>%
  dplyr::filter(n > 10) %>% # data protection
  mutate_at(vars(datum, GERAETENR, CODE1, EINHEIT), stringr::str_trim) %>%
  mutate(string = paste(labname, datum, GERAETENR, 'AM', 
                        CODE1, EINHEIT, med, n, sep = ";"))

text <- paste(output$string, collapse = "\n")

# just send plain text mails
text <- iconv(text, from = 'UTF-8', to = 'ASCII//TRANSLIT')

sendmail(mail.from, mail.to,
         paste0(strftime(anaDate,'%Y-%m-%d'), ' Empower Project '),
         text, 
         headers = list('Reply-To' = mail.replyTo),
         control = list('smtpServer' = mail.smtphost))
cat('Done.\n')
