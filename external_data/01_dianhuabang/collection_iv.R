library('smbinning')  #最优分箱
library('DMwR')  #检测离群值
library('xlsx')  

####################################################################################
###客户基本信息 和 征信数据衍生变量
readFilePath<-"C:/Users/Administrator/Desktop/data.csv"
df<-read.csv(readFilePath)
head(df)
names(df)


#smbinning(df, y, x, p = 0.05)
#df: 数据
#y： 二分类变量(0,1) 整型
#x：连续变量：至少满足10 个不同值，取值范围有限
#p：每个Bin记录数占比，默认5% (0.05) 范围0%-50%
#smbinning.plot, smbinning.sql,and smbinning.gen.

####################################################################################
# Information Value for all variables in one step ---------------------------
smbinning.sumiv(df=df,y="y") # IV for eache variable

# Plot IV for all variables -------------------------------------------------
sumivt=smbinning.sumiv(df,y="y")
sumivt # Display table with IV by characteristic
par(mfrow=c(1,1))
smbinning.sumiv.plot(sumivt,cex=1) # Plot IV summary table

####################################################################################


result1<-smbinning(df=df,x="var94",y="y",p=0.05)
smbinning.plot(result1,option="WoE",sub="var94")
r1 <- merge(result1$x,result1$ivtable)

result2<-smbinning(df=df,x="var97",y="y",p=0.05)
smbinning.plot(result2,option="WoE",sub="var97")
r2 <- merge(result2$x,result2$ivtable)

result3<-smbinning(df=df,x="var8",y="y",p=0.05)
smbinning.plot(result3,option="WoE",sub="var8")
r3 <- merge(result3$x,result3$ivtable)

result4<-smbinning(df=df,x="var139",y="y",p=0.05)
smbinning.plot(result4,option="WoE",sub="var139")
r4 <- merge(result4$x,result4$ivtable)

result5<-smbinning(df=df,x="var7",y="y",p=0.05)
smbinning.plot(result5,option="WoE",sub="var7")
r5 <- merge(result5$x,result5$ivtable)

result6<-smbinning(df=df,x="var53",y="y",p=0.05)
smbinning.plot(result6,option="WoE",sub="var53")
r6 <- merge(result6$x,result6$ivtable)

result7<-smbinning(df=df,x="var113",y="y",p=0.05)
smbinning.plot(result7,option="WoE",sub="var113")
r7 <- merge(result7$x,result7$ivtable)

result8<-smbinning(df=df,x="var27",y="y",p=0.05)
smbinning.plot(result8,option="WoE",sub="var27")
r8 <- merge(result8$x,result8$ivtable)

result9<-smbinning(df=df,x="var141",y="y",p=0.05)
smbinning.plot(result9,option="WoE",sub="var141")
r9 <- merge(result9$x,result9$ivtable)

result10<-smbinning(df=df,x="var19",y="y",p=0.05)
smbinning.plot(result10,option="WoE",sub="var19")
r10 <- merge(result10$x,result10$ivtable)

result11<-smbinning(df=df,x="var17",y="y",p=0.05)
smbinning.plot(result11,option="WoE",sub="var17")
r11 <- merge(result11$x,result11$ivtable)

r_total <- rbind(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11)
outFilePath <- "F:/TS/external_data_test/电话邦/通善_测试结果/output/r_best_binging.xlsx"
write.xlsx(r_total, outFilePath)  




