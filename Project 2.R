

rm(list=ls())

install.packages("edgar")
library(edgar)


quarter<-c(1,2)

make_URL<-function(Q) {
  paste0("https://www.sec.gov/Archives/edgar/full-index/",
         2018,
         "/QTR",Q,
         "/master.idx")
}
web.url_Q1<-make_URL(1)
web.url_Q2<-make_URL(2)

dest_file_name_Q1<-"./Data/2018Q1"

dest_file_name_Q2<-"./Data/2018Q2"

download.file(web.url_Q1,dest_file_name_Q1,mode="wb")

download.file(web.url_Q2,dest_file_name_Q2,mode="wb")

Q1<-readLines(dest_file_name_Q1, n=30000)

datalines <- Q1[-(1:11)]

separatedlines <- strsplit(datalines, "\\|") #list
edgar.matrix <- do.call(rbind, separatedlines) #matrix

edgar.dataframe <- as.data.frame(edgar.matrix)

#Choosing 10K
index.10K <- grep("^10-K$", edgar.dataframe[,3])

my_data_frame<-(edgar.dataframe[index.10K,])

#Dowloading files for Q1 and Q2 2018

for(row in 1:nrow(my_data_frame)){
  my_urls<-paste0("https://www.sec.gov/Archives/", my_data_frame[row ,5])
  CIK_file_name<-paste0("./Data/", 
                        my_data_frame[row,1],".txt")
  download.file(my_urls,CIK_file_name,mode="wb") 
  Sys.sleep (1)
  
}

###Building the function, where we clean the file using regular expresions and count searched expresions
###("sustainability" and "sustainable") 

process_file<-function(CIK_file_name){

one_file<- readLines(CIK_file_name)
header<-grep("<TYPE>10-K", one_file,  ignore.case = F)
one_file_vol2<-one_file[-(1:(header-1))]
end<-grep("?</DOCUMENT", one_file_vol2, ignore.case = F)
one_file_vol3<-one_file_vol2[1:end[1]]

#remove html tags
without_tags<-gsub("<.*?>", "", one_file_vol3)

#remove html entities
without_entities<-gsub("\\&.*?\\;","", without_tags)

#remove numbers
without_numbers<-gsub("[[:digit:]]","",without_entities)

#remove excessive white spaces
without_spaces<-gsub("[[:space:]]+"," ", without_numbers)

#remove empty lines
empty_lines<-grep("^[[:space:]]*$",without_spaces)
without_empty_lines<-without_spaces[-empty_lines]

#CIK number
CIK_number_vol1<-gsub("^.*/", "",CIK_file_name)
CIK_number_vol2<-gsub("\\.txt$","", CIK_number_vol1)
CIK_number<-strtoi(CIK_number_vol2)

#diving each line into words
words<-strsplit(without_empty_lines," ")
# let's do one line out of these words
all_words<- unlist(words)

empty_words<-grep("^[[:space:]]*$",all_words)
without_empty_words<-all_words[-(empty_words)]

#how many words
word_count<-length(without_empty_words)


key_words<-grep("(sustainability)|(sustainable)",without_empty_words, ignore.case = T )
key_words_count<-length(key_words)

#per 1000 words
per_1000<-(key_words_count/word_count)*1000

result<-list(CIK_number, key_words_count,per_1000)
return(result)
}

all_rows<-list()

for(row in 1:nrow(my_data_frame)){
  
  print(row)
  CIK_file_name<-paste0("./Data/", 
                        my_data_frame[row,1],".txt")
  new_row<-process_file(CIK_file_name)
  all_rows<-append(all_rows,new_row)
  
}  

final_data_frame<-as.data.frame(matrix(all_rows,ncol=3,byrow=T))

rm(list=ls())

save(final_data_frame, "finalDataFrame.RData")

load("finalDataFrame.Rdata")
########3filtring data ( we do not want 0 value rows)
Filtered_data_frame<-final_data_frame[final_data_frame$V3>0,]

#sorting data and changing name of header "V1"

sorted_data_frame<-final_data_frame[!is.na(final_data_frame$V3) & final_data_frame$V3>0,]
names(sorted_data_frame)[1]<-"CIK"

#reading yahoo file ("yahoo.data")

load("yahoo_data.Rdata")

#merging data
merged_data<-merge(yahoo.data, sorted_data_frame, by="CIK")

library(splines)

result_data_frame<-data.frame(x=log(merged_data$sustainability.score.yahoo), 
                              y=log(unlist(merged_data[["V3"]])))
#regression model

#making a plot

library(ggplot2)
install.packages("ggthemes")
library(ggthemes)
ggplot(result_data_frame, aes(x =y, y =x)) + 
  geom_point() +
  ggtitle("Sustainability scores") +
  xlab("Text-based scaled score") + 
  ylab("Yahoo score") +
  geom_smooth(method = lm)
