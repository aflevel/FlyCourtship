#!/usr/bin/bash

#for FILE in `ls [1-9]*.mp4 | grep -v sized`; do
#OR

printf 'COLOR=colorRampPalette(c("red", "yellow", "green"))(500)\n' > Plotting.r
printf '\n' >> Plotting.r
printf 'args <- commandArgs(trailingOnly = TRUE)\n' >> Plotting.r
printf 'FILENAME=args[1]\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'Data=read.csv(FILENAME,header=F)\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'Data=Data[order(Data[,1]),]\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'Data[Data[,2]>quantile(Data[,2],.9),2]=NA\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'png(gsub(".csv",".png",FILENAME),width=800,height=200)\n' >> Plotting.r
printf 'par(mar=c(3,0,2,0))\n' >> Plotting.r
printf 'SMOOTH=smooth.spline(Data[!is.na(Data[,2]),1],Data[!is.na(Data[,2]),2],spar=.6)\n' >> Plotting.r
printf 'SMOOTH.val=predict(SMOOTH,Data[!is.na(Data[,2]),1])$y\n' >> Plotting.r
printf 'SMOOTH.DERI=predict(SMOOTH,Data[!is.na(Data[,2]),1],deriv=1)$y\n' >> Plotting.r
printf "plot(SMOOTH.val~Data[!is.na(Data[,2]),1],col=grey(.6),type=\"line\",lwd=1.5,main=FILENAME,xaxt='n',yaxt='n')\n" >> Plotting.r
printf 'TIMES=seq(30,max(Data[,1]),30)\n' >> Plotting.r
printf "TIMES.sec=ceiling(TIMES %%%% 60)\n" >> Plotting.r
printf 'TIMES.min=floor(TIMES/60)\n' >> Plotting.r
printf "TIMES.txt=paste(TIMES.min,\"\\\'\",TIMES.sec,sep=\"\")\n" >> Plotting.r
printf 'axis(side=1,at=TIMES,labels=TIMES.txt,las=2,mgp=c(3,0.5,0))\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'W=1000\n' >> Plotting.r
printf 'MINs=c()\n' >> Plotting.r
printf 'for (i in 1:floor(length(SMOOTH.DERI)/W)) MINs=c(MINs,which(SMOOTH.DERI==min(SMOOTH.DERI[(i*W-W+1):(i*W)],na.rm=T)))\n' >> Plotting.r
printf 'abline(v=Data[!is.na(Data[,2]),1][MINs[order(SMOOTH.DERI[MINs])][1:5]],col=2,lwd=3)\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'TIMES=Data[!is.na(Data[,2]),1][MINs[order(SMOOTH.DERI[MINs])][1:5]]\n' >> Plotting.r
printf 'TIMES.sec=ceiling(TIMES %%%% 60)\n' >> Plotting.r
printf 'TIMES.min=floor(TIMES/60)\n' >> Plotting.r
printf "TIMES.txt=paste(TIMES.min,\"\\\'\",TIMES.sec,sep=\"\")\n" >> Plotting.r
printf 'text(TIMES-10,par("usr")[4]-seq(.1,.5,.1)*par("usr")[4],TIMES.txt,cex=2,las=2)\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'W=25\n' >> Plotting.r
printf 'MIN=c()\n' >> Plotting.r
printf 'MU=c()\n' >> Plotting.r
printf 'for (i in ceiling(1+W):floor(nrow(Data)-W)) {\n' >> Plotting.r
printf 'Data.sub=Data[(i-W):(i+W),2]\n' >> Plotting.r
printf 'MIN=c(MIN,min(Data.sub,na.rm=T))\n' >> Plotting.r
printf 'MU=c(MU,mean(Data.sub,na.rm=T))\n' >> Plotting.r
printf '}\n' >> Plotting.r
printf 'LOW=MU-MIN\n' >> Plotting.r
printf 'SEC=Data[ceiling(1+W):floor(nrow(Data)-W),1]\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'SMOOTH=smooth.spline(SEC[!is.na(LOW)],LOW[!is.na(LOW)],spar=.6)\n' >> Plotting.r
printf 'SMOOTH.LOW=predict(SMOOTH,SEC[!is.na(LOW)])$y\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'STD=sum(SMOOTH.LOW<quantile(LOW,.1,na.rm=T))\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'if (STD<10) {\n' >> Plotting.r
printf 'STATUS="NOTHING"\n' >> Plotting.r
printf '} else if (STD>10&STD<200) {\n' >> Plotting.r
printf 'STATUS="PARTIAL"\n' >> Plotting.r
printf '} else STATUS="FULL ON"\n' >> Plotting.r
printf '\n' >> Plotting.r
printf 'text(80,par("usr")[4]-.05*par("usr")[4],STATUS,col=COLOR[STD+1],cex=2)\n' >> Plotting.r
printf 'print(paste(FILENAME,STD))\n' >> Plotting.r
printf 'dev.off()\n' >> Plotting.r

FILE=$1

	WxH=`ffmpeg -i $FILE 2>&1 | grep -E 'Stream.*Video' | cut -d, -f4`
	W=`echo $WxH | cut -dx -f1`
	H=`echo $WxH | cut -dx -f2`

	PLOT=Log_`echo $FILE | cut -d'-' -f1 | cut -d. -f1`_2sec

	Rscript Plotting.r $PLOT.csv
	until [ -e $PLOT.png ]; do sleep 1; done

	ffmpeg \
		-i $PLOT.png \
		-vf scale=$((2*W)):$((2*H/4)) \
		-q:v 1 \
		-y \
		${PLOT}_sized.png

	ffmpeg \
		-i $FILE \
		-vf scale=$((2*W)):$((2*H)) \
		-strict -2 \
		-q:v 1 \
		-y `echo $FILE | cut -d'-' -f1 | cut -d. -f1`_sized.mp4

	ffmpeg \
		-i `echo $FILE | cut -d'-' -f1 | cut -d. -f1`_sized.mp4 \
		-i ${PLOT}_sized.png \
		-q:v 1 -filter_complex "[0:v]pad=0:ih+50[bg];[bg][1:v]overlay=0:H-h,format=yuv420p[v]" \
		-map "[v]" \
		-map 0:a \
		-c:v libx264 \
		-c:a aac \
		-strict -2 \
		-movflags +faststart \
		-y `echo $FILE | cut -d'-' -f1 | cut -d. -f1`_formatted.mp4

	rm ${PLOT}_sized.png `echo $FILE | cut -d'-' -f1 | cut -d. -f1`_sized.mp4 Plotting.r

