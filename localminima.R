# run this by starting R (type R at the bash prompt)
# then type source("localminima.R") at the R prompt. 

height <- 1000
width <- 1000

area <- seq(100000,10000000,10000)
broadcast <- seq(100,1000,100)
hops <- 1:5

# exepcted local minima for uniform distribution
elm.uniform= function (area, br, h) {
  area/(pi*(br*h)^2)
}

par(mfrow=c(2,2))
#title("Effect of different parameters on expected number of local minima")

# As broadcast radius increases
plot(broadcast, elm.uniform(1000000,broadcast,1), type='l')
title("Vary broadcast radius")

# As hops increases
plot(hops, elm.uniform(1000000,200,hops), type='l')
title("Vary neighbor hops")

# As area increases
plot(area, elm.uniform(area,200,1), type='l')
title("Vary size of physical space")

#for (hop in hops) {
#  if (hop == 1) {
#    print(lm(n,broadcast,hop))
#    plot(broadcast, lm(n,broadcast,hop), type='l',
#         xlab="Broadcast Radius", ylab="Expected Local Minima")
#    title("Expected number of local minima for a uninform distribution") 
#  }
#    else {
#      lines(broadcast, lm(n,broadcast,hop),  ylim=c(0,50), type='l')
#    }
#}



