clear,clc;
a=zeros(6,6);
a(1,[2,3])=[5,3];
a(2,4)=2;
a(3,[2,5])=[1,4];
a(4,[3,5,6])=[1,3,2];
a(5,6)=5;
b=zeros(6,6);
b(1,[2,3])=[3,6];
b(2,4)=8;
b(3,[2,5])=[2,2];
b(4,[3,5,6])=[1,4,10];
b(5,6)=2;
prob=optimproblem('ObjectiveSense','max');
f=optimvar('f',6,6,'LowerBound',zeros(6,6));
w=optimvar('w','LowerBound',0);
prob.Objective = w-0.1*sum(b.*f);
prob.Constraints.con1 = [sum(f(1,:))==w
                         sum(f(:,6))==w];
con2=optimconstr(4);
for i=2:1:5
    con2(i-1) = sum(f(i,:))==sum(f(:,i));
end
prob.Constraints.con2=con2;
prob.Constraints.con3 = f<=a;
[sol, fval, flag, out] = solve(prob);