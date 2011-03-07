# run this by starting R (type R at the bash prompt)
# then type source("plot.R") at the R prompt. 

metadata <- read.csv("log-2011-02-02T21:09:32-05:00", nrows=3, header=0, sep=":")
log <- read.csv("log-2011-02-02T21:09:32-05:00", skip=3)

# start the PNG device driver to save the graph
# png(filename="graphs/lms-recall2.png", height=400, width=600, bg="white")

replicas <- log$replicas
put.recall <- log$put.recall
get.recall <- log$get.recall
perf = get.recall*put.recall

# exepcted local minima for uniform distribution
elm.uniform= function (area, br, h) {
  area/(pi*(br*h)^2)
}

size = metadata[3,2]*metadata[4,2]
print(size)
hops = metadata[8,2]
print(hops)
broadcast = metadata[5,2]
print(broadcast)
explm = elm.uniform(size, broadcast, hops)
print(explm)

colours = c("darkorange4", "darkorange2","darkolivegreen3", "darkolivegreen4",
  "blue3", "blue4", "aquamarine3", "aquamarine4", "brown3", "brown4")

# ann=False turns off automatic axis annotations (we specify
# them manually below)
plot(replicas, put.recall, type="o", lty=3, ylim=range(0,1),
     ann=FALSE, col=colours[1])
lines(replicas, get.recall, type="o", lty=3, pch=21, col=colours[2])
lines(replicas, perf, type="o", lty=1, pch=22, col=colours[3])
abline(v=explm)
title(xlab="Replicas", ylab="Recall",
      main="LMS Performance\nNodes=500,Area=1000000, BR = 200, Hops=1")


legend(40,0.20, legend=c("PUT Recall","GET Recall", "GET*PUT"),
       border=FALSE, col=colours, lty=c(3,31), pch=c(21,21,22), cex=0.8)

# turn the device driver off (flushes the PNG output as well)
#dev.off()
