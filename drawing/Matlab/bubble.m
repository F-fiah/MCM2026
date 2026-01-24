x=rand(20,1)*100;
y=rand(20,1)*100;
marker_size=rand(20,1)*100;
color=rand(20,1);
subplot(1,2,1);
bubblechart(x,y,marker_size,color);
bubblesize([5,30]);
colorbar;

z=rand(20,1)*100;
subplot(1,2,2);
h=bubblechart3(x,y,z,marker_size,color);
bubblesize([10,40]);
colorbar;