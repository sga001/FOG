# run this by starting R (type R at the bash prompt)
# then type source("plot.R") at the R prompt. 

# fill in the most recent logfile name here
log <- read.csv("log-2011-01-27T22:37:01-05:00")
# start the PNG device driver to save the graph
#png(filename="graphs/lms-recall2.png", height=400, width=600, bg="white")

nodes <- log$broadcast
put_recall <- log$put.recall
get_recall <- log$get.recall
colours = c("darkorange4", "darkorange2")
plot(nodes, put_recall, type="o", ylim=range(0,1), ann=FALSE, col=colours[1])
title(xlab="Broadcast Radius", ylab="Recall", main="LMS Performance\nHops=1, Broadcast Radius=100, Width = Height = 1000")
lines(nodes, get_recall, type="o", lty=2, pch=22, col=colours[2])
legend(100,1.0, legend=c("PUT Recall 2 Hops",
                  "GET Recall 2 hops"), border=FALSE, col=colours, lty=1:2, pch=21:22) 

# turn the device driver off (flushes the PNG output as well)
#dev.off()
