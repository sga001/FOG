# run this by starting R (type R at the bash prompt)
# then type source("plot.R") at the R prompt. 

# fill in the most recent logfile name here
log0 <- read.csv("log-2011-01-27T14:23:01-05:00")
log <- read.csv("log-2011-01-27T22:37:01-05:00")
# start the PNG device driver to save the graph
#png(filename="graphs/lms-recall2.png", height=400, width=600, bg="white")

nodes <- log[0:14, 'broadcast']

put_recall1 <- log0[0:14,'put.recall']
get_recall1 <- log0[0:14,'get.recall']

put_recall2 <- log[0:14,'put.recall']
put_recall3 <- log[15:28,'put.recall']
put_recall4 <- log[29:42,'put.recall']
put_recall5 <- log[43:56,'put.recall']

get_recall2 <- log[0:14,'get.recall']
get_recall3 <- log[15:28,'get.recall']
get_recall4 <- log[29:42,'get.recall']
get_recall5 <- log[43:56,'get.recall']

colours = c("darkorange4", "darkorange2","darkolivegreen3", "darkolivegreen4",
  "blue3", "blue4", "aquamarine3", "aquamarine4", "brown3", "brown4")
plot(nodes, put_recall1, type="o", lty=3, ylim=range(0,1),
     ann=FALSE, col=colours[1])
title(xlab="Broadcast Radius", ylab="Recall", main="LMS Performance\nNodes=500, Width=Height=1000, replicas=10")
lines(nodes, get_recall1, type="o", lty=1, pch=22, col=colours[2])

lines(nodes, put_recall2, type="o", lty=3, pch=21, col=colours[3])
lines(nodes, get_recall2, type="o", lty=1, pch=22, col=colours[4])
lines(nodes, put_recall3, type="o", lty=3, pch=21, col=colours[5])
lines(nodes, get_recall3, type="o", lty=1, pch=22, col=colours[6])
lines(nodes, put_recall4, type="o", lty=3, pch=21, col=colours[7])
lines(nodes, get_recall4, type="o", lty=1, pch=22, col=colours[8])
lines(nodes, put_recall5, type="o", lty=3, pch=21, col=colours[9])
lines(nodes, get_recall5, type="o", lty=1, pch=22, col=colours[10])

legend(600,0.40, legend=c("PUT Recall 1 Hop","GET Recall 1 hop",
                   "PUT Recall 2 Hops","GET Recall 2 hops",
                   "PUT Recall 3 Hops","GET Recall 3 hops",
                   "PUT Recall 4 Hops","GET Recall 4 hops",
                   "PUT Recall 5 Hops","GET Recall 5 hops"),
       border=FALSE, col=colours, lty=c(3,1), pch=21:22, cex=0.8)

# turn the device driver off (flushes the PNG output as well)
#dev.off()
