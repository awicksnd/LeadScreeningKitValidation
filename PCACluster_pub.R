# LOAD DATA
library(readxl)
library(scatterplot3d)
library(plot3D)
library(rgl)
library(plotly)
library(ggplot2)
theme_set(theme_bw() + theme(legend.position = "top"))

LSKAllData <- read_excel("/Users/alyssawicks/Documents/RStudio/PCA_Bins_29May23.xlsx",
                         sheet = "Bins")

street<- LSKAllData[1:402,c("Soil - Street")]
yard <- LSKAllData[1:402,c("Soil - Yard")]
drip <- LSKAllData[1:402,c("Soil - Dripline")]
ext <- LSKAllData[1:402,c("Paint - Exterior")]
int <- LSKAllData[1:402,c("Paint - Interior")]
thresh <- LSKAllData[1:402,c("Dust - Threshold")] 
old <- LSKAllData[1:402,c("Dust - Old dust")]
win <- LSKAllData[1:402,c("Dust - Windowsills")]
clab <- LSKAllData[1:402,c("Data_Set")]
dlab <- LSKAllData[1:402,c("Category")]
elab <- LSKAllData[1:402,c("Total")]
flab <- LSKAllData[1:402,c("Sum")]

samples <- cbind(street,yard,drip,ext,int,thresh,old,win)
samples1 <- cbind(street,yard,drip,ext,int,thresh,old,win,clab,dlab,elab,flab)
df1 <- as.data.frame(samples1)
df_omit1 <- na.omit(df1)
df_omit <- df_omit1[,c(1:8)]

head(df_omit)
summary(df_omit)

df_omit_norm <- scale(df_omit)
head(df_omit_norm)
summary(df_omit_norm)

# CORRELATION MATRIX ---
library(ggcorrplot)
corr_matrix <- cor(df_omit_norm)

ggcorrplot(corr_matrix, type = "upper", outline.col = "gray") +
  scale_fill_gradient2(low = "black",mid = "white", high = "#E46726", limits = c(-.2, 1))


# PCA  ---
data.pca <- princomp(corr_matrix)
summary(data.pca)
data.pca$loadings[, 1:2]

# SCREE PLOT ---
library("factoextra")
fviz_eig(data.pca, addlabels = TRUE)
fviz_pca_var(data.pca, col.var = "black")

# CONTRIBUTION OF EACH VARIABLE ---
fviz_cos2(data.pca, choice = "var", axes = 1:2)
# A low value means that the variable is not perfectly represented by that component. 
# A high value, on the other hand, means a good representation of the variable on that component.

# BIPLOT WITH COS2
fviz_pca_var(data.pca, col.var = "cos2",
             gradient.cols = c("black", "orange", "green"),
             repel = TRUE)
# High cos2 attributes are colored in green, Mid cos2 attributes have an orange color and
# low cos2 attributes have a black color

pcas <- data.pca$loadings[, 1:3]
# pcas <- data.pca$loadings[, 1:4]

pcaxyz <- df_omit_norm %*% pcas

gpca <- data.frame(pcaxyz,df_omit1[,c("Data_Set")],df_omit1[,c("Category")],
                   df_omit1[,c("Total")],df_omit1[,c("Sum")])
colnames(gpca) <- c('PC-1','PC-2','PC-3','DataSet','Year','GenCategory',
                    'Category')

# 2D Nicely Colored, General Categories
fig2 <- qplot(x = gpca$`PC-1`, y = gpca$`PC-2`, data = gpca,
              color = gpca$DataSet, xlab = "PC-1", ylab = "PC-2")
fig2


# 2D Nicely Colored, Traceable, General Categories
fig5 <- plot_ly(gpca, x = gpca$`PC-1`, y = gpca$`PC-2`, 
                color = gpca$GenCategory, 
                colors = c('#999999','#E69F00','#56B4E9','#6F134d','#2E24d3',
                                    '#636EFA','#EF553B','#00CC96') ) %>%
                                      add_markers(size = 12)
fig5 <- fig5 %>%
  layout(
    scene = list(bgcolor = "#e5ecf6")
  )

fig5




fviz_nbclust(pcaxyz, FUNcluster=cluster::pam, k.max = 7)
# Silhouette suggests 6 clusters

pcaxy <- gpca[,1:2]

pam1<-eclust(pcaxy, "pam", k=6) # factoextra::

# 2D Nicely Colored, Traceable, All Categories
fig6 <- plot_ly(gpca, x = gpca$`PC-1`, y = gpca$`PC-2`,
                color = gpca$Category,
                colors = c('#6F134d','#442E44','#999999','#513CBA','#2E24d3',
                                    '#636EFA','#8A42F3','#9F32D3',
                                    '#E10A52','#E83A42','#EF553B',"#B42111",'#A55111',
                                    '#D75111', '#EF884B','#E69F00','#567903',
                                    '#00BC32', '#00CC96','#88ECCC','#99CCCC',
                                    '#549994','#39BBE5','#56B4E9')) %>%
                                      add_markers(size = 12)
fig6 <- fig6 %>%
  layout(
    scene = list(bgcolor = "#e5ecf6")
  )

fig6



 



