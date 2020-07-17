import numpy as np
import re
import copy

'''
    第一列，发送端，第二列接受端，第三列是否接收到，第四列传输时长
'''

def readLog(filename):
    totalLogList=[]
    logList=[]
    with open(filename, 'rb') as file_to_read:
        index=0
        for line in file_to_read:
            strLine= str(line)
            if (index>=3):
                    oneList=strLine.split( )
                    #print(len(oneList))
                    if (len(oneList)==4):
                        try:
                            row=[]
                            row.append(int(oneList[1]))
                            row.append(int(oneList[2]))
                            row.append(False)
                            row.append(0)
                            logList.append(row)
                            #print(oneList)
                        except:
                            pass
            index=index+1
        
    with open(filename, 'rb') as file_to_read:
        counter=0
        currentCounter=0
        tempLogList=copy.deepcopy(logList)
        for line in file_to_read:
            strLine=str(line)
            splitLine=re.split(',|\.|\\r| ',strLine)
            if "counter is" in strLine:
                #print(splitLine)
                counter=int(splitLine[-2])
                if (counter-2==currentCounter):
                    #print(tempLogList)
                    currentCounter=currentCounter+1
                    totalLogList.append(tempLogList)
                    tempLogList=copy.deepcopy(logList)

            if "receives packet from node" in strLine and currentCounter==counter-1:
                #print("#################")
                    
                for oneList in tempLogList:
                    if(str(oneList[0])==splitLine[8] and str(oneList[1])==splitLine[3]):
                        oneList[2]=True
                        oneList[3]=int(splitLine[-2])-int(splitLine[-7])
                        #print(logList)
                    
                        
                
                #print (splitLine)
            
        totalLogList.append(tempLogList)
        print(totalLogList)
        return totalLogList

def calculateSum (totalLogList):
    sum=0.0
    for counter in totalLogList:
        sum=sum+len(counter)
    return sum

def calculateTotalDelay (totalLogList):
    TotalDelay=0.0
    for counter in totalLogList:
        for oneList in counter:
            if (oneList[2]):
                TotalDelay=TotalDelay+oneList[3]
    return TotalDelay

def calculateLoss (totalLogList):
    sum=0.0
    for counter in totalLogList:
        for oneList in counter:
            if (oneList[2]==False):
                sum=sum+1
    return sum
    
if __name__ == "__main__":
    totalLogList=readLog("D:\Onedrive\OneDrive - bupt.edu.cn\无线传感器网络\\WSN实验\\17班第3组 王洲洋 杜瑞年 康凯\\screen.log")
    transmitSum=calculateSum(totalLogList)
    print("Nodes Totally Transmit ", transmitSum, " Times")
    print("Average Transmit Delay: ", calculateTotalDelay (totalLogList)/transmitSum)
    print("Packet Loss Rate: ", calculateLoss (totalLogList)/transmitSum)
    
    
    
    
    
    