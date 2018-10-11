# edgar

The objective of the task is to measure the sustainability score for particulars USA companies using EDGAR system (Electronic Data Gathering Analysis And Retrieval ) 
for Q1 of 2018 and compare them with "Yahoo sustainability score".

To achive it we download the master index files of Q1 form EDGAR and using regular expression we clean the data to creat data frame:

1) We find the meningful part of document ( 10-K)
2) We remove html tags and entities
3) We remove all the numbers, whitespaces and empty lines

Afterwords, we calculate what is the frequency of "sustainability", "sustainable" words in the each row ( per 1000 word). We remove the row with the result 0.

The last step is to compare our results with Yahoo sustainability score.
