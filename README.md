# SwlToEmpower
Small script to extract laboratory data from Swisslab and send it to the Empower quality control project. Written in R.

This script extracts laboratory measurements directly from the database of the Laboratory Information System [Swisslab](https://www.roche.de/diagnostics/systeme/it-loesungen/swisslab-laborinformationsystem.html#SWISSLAB-Laboratory-Information-System). It then calculates daily medians and transmits them to the Empower project via email for quality control purposes. This script currently only covers the "percentiler" and not the "flagger" part. 

Please contact Linda Thienpont (linda.thienpont\<at\>ugent.be) of Thienpont & Stöckl Wissenschaftliches Consulting GbR
if you want to participate in the Empower project.

There are serveral publications from the Empower project that provide more in-depth information: 

+ [The Empower project - a new way of assessing and monitoring test comparability and stability.](https://doi.org/10.1515/cclm-2014-0959)
+ [On-line flagging monitoring - a new quality management tool for the analytical phase.](https://doi.org/10.1515/cclm-2015-0066)
+ [Using “big data” to describe the effect of seasonal variation in thyroid-stimulating hormone](https://doi.org/10.1515/cclm-2016-0500)
  

## Requirenments
+ [jTDS JDBC Driver](http://jtds.sourceforge.net/) to connect to the Swisslab Sybase database
+ Java oder Openjdk JRE for jTDS
+ [R programming language](https://www.r-project.org/) for the actual script
+ lots of R packages, see the library definition in the script
+ [Cron job](https://en.wikipedia.org/wiki/Cron) to run the script daily
+ Email Server to send the mail 


## Installation
Just edit the parameters in the *percentiler.R* script and upload the file on your (linux) server. You have to supply your server settings and analyte codes as described in the *percentiler.R* file. If the server has access to the internet, you should be able to install the required R packages using [CRAN](https://cran.r-project.org/) and the R command [install.packages()](https://www.r-bloggers.com/installing-r-packages/). CRAN will take care of your R dependencies. If you do not have internet access this [tutorial](https://www.r-bloggers.com/installing-packages-without-internet/) might help you. 

Please test the script by sending mails to yourself first. If everything works fine you need to tell Linda Thienpont that you are ready. She will need to know your analytical devices and their Swisslab codes. 

Once you are sure that everything works well you can set up a cron job to execute the script daily. This is mine that starts every day at 17:15:
    
    15 17 * * * /usr/bin/Rscript /home/ab/percentiler.R

## Contact
If you have problems you can write me an email to andreas.bietenbeck\<at\>tum.de. You can also just open a new [issue](https://github.com/acnb/SlToPercentiler/issues/new).
