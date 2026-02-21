x=[-3.0 -2.0 -1.0 0 1.0 2.0 3.0]';
y=[-0.2774 0.8958 -1.5651 3.4565 3.0601 4.8568 3.8982]';
[x,i]=sort(x); % 对x按升序排列，同时返回排序后的索引i
y=y(i); % 根据索引i重新排列y，让y的顺序与排序后的x

xi=min(x)+[0:100]/100*(max(x)-min(x)); % 在x的min值和max值之间，生成101 个均匀分布的高密度点

for i=1:4
    N=2*i-1;
    [th,err,yi]=polyfits(x,y,N,xi);
    subplot(2,2,i);
    plot(x,y,'k*')
    hold on
    plot(xi,yi,'g:', 'LineWidth',1.5);
    title(['The ',num2str(N),'th Polynomial Curve Fitting'])
    grid on
end