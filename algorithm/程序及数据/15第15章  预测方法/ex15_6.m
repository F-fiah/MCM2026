clc,clear, fid = fopen('data15_6.txt');
a = textscan(fid, '%s'); b=strjoin(a{:});
for i=0:1
    for j=0:1
        s=[int2str(i),int2str(j)]; 
        f(i+1,j+1)=length(strfind(b,s)); 
    end
end
fs=sym(sum(f,2));
f=f./repmat(fs,1,size(f,2)) 
