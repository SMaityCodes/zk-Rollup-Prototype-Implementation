pragma circom  2.0.0;
template Fact(n){
 signal input in;
 signal output out;

 signal arr[n+1];
 arr[0]<==1;
for(var i=1;i<=n;i++){
 arr[i]<==arr[i-1]*i;
}
in===n;
out<==arr[n];
}
component main=Fact(6);


