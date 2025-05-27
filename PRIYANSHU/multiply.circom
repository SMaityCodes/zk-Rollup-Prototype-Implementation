pragma circom 2.0.0;
template Multiply() {
signal input x;
signal input y;
signal output product;
product <==x*y;
}
component main=Multiply();
